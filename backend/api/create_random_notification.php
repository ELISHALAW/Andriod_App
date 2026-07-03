<?php
// ====================== CORS & Headers ======================
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Use POST.',
        'data' => null,
    ]);
    exit();
}

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid JSON payload.',
        'data' => null,
    ]);
    exit();
}

$userId = isset($input['user_id']) ? intval($input['user_id']) : 0;
if ($userId <= 0) {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'User ID is required.',
        'data' => null,
    ]);
    exit();
}

$host = 'localhost';
$db_user = 'root';
$db_pass = '';
$db_name = 'android_app';

$conn = new mysqli($host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $conn->connect_error,
        'data' => null,
    ]);
    exit();
}

$createTableSql = "CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(120) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(30) NOT NULL DEFAULT 'info',
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (user_id)
)";

if (!$conn->query($createTableSql)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to prepare notifications table: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$alerts = [
    [
        'title' => 'Appointment confirmed',
        'message' => 'Your consultation booking has been confirmed for tomorrow.',
        'type' => 'success',
    ],
    [
        'title' => 'Payment reminder',
        'message' => 'Your latest invoice is ready for review and payment.',
        'type' => 'warning',
    ],
    [
        'title' => 'New announcement',
        'message' => 'A new update has been posted by the admin team.',
        'type' => 'info',
    ],
    [
        'title' => 'Document uploaded',
        'message' => 'A new document has been uploaded to your account.',
        'type' => 'success',
    ],
    [
        'title' => 'Schedule changed',
        'message' => 'One of your upcoming appointments has a new time slot.',
        'type' => 'warning',
    ],
    [
        'title' => 'Support reply',
        'message' => 'The support team has replied to your latest request.',
        'type' => 'info',
    ],
    [
        'title' => 'Profile incomplete',
        'message' => 'Add your phone number and address to complete your profile.',
        'type' => 'profile',
    ],
    [
        'title' => 'System maintenance',
        'message' => 'The service may be unavailable for a short time tonight.',
        'type' => 'warning',
    ],
];

$alert = $alerts[random_int(0, count($alerts) - 1)];
$stmt = $conn->prepare(
    'INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)'
);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$stmt->bind_param(
    'isss',
    $userId,
    $alert['title'],
    $alert['message'],
    $alert['type']
);

if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to create notification: ' . $stmt->error,
        'data' => null,
    ]);
    $stmt->close();
    $conn->close();
    exit();
}

$notificationId = $stmt->insert_id;
$stmt->close();

$selectStmt = $conn->prepare(
    'SELECT id, user_id, title, message, type, is_read, created_at
     FROM notifications
     WHERE id = ?
     LIMIT 1'
);

if (!$selectStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Notification created, but reload failed: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$selectStmt->bind_param('i', $notificationId);
$selectStmt->execute();
$result = $selectStmt->get_result();
$notification = $result->fetch_assoc();

if ($notification) {
    $notification['id'] = intval($notification['id']);
    $notification['user_id'] = intval($notification['user_id']);
    $notification['is_read'] = intval($notification['is_read']);
}

http_response_code(201);
echo json_encode([
    'success' => true,
    'message' => 'Random alert generated.',
    'data' => $notification,
]);

$selectStmt->close();
$conn->close();
?>
