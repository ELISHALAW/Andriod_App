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

$createTableSql = "CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    sender VARCHAR(120) NOT NULL,
    subject VARCHAR(160) NOT NULL,
    body TEXT NOT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (user_id)
)";

if (!$conn->query($createTableSql)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to prepare messages table: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$countStmt = $conn->prepare('SELECT COUNT(*) FROM messages WHERE user_id = ?');
if (!$countStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$countStmt->bind_param('i', $userId);
$countStmt->execute();
$countStmt->bind_result($count);
$countStmt->fetch();
$countStmt->close();

if ($count === 0) {
    $seedStmt = $conn->prepare(
        'INSERT INTO messages (user_id, sender, subject, body) VALUES (?, ?, ?, ?)'
    );

    if ($seedStmt) {
        $samples = [
            ['Support team', 'Welcome to your inbox', 'You can now receive account updates and support replies here.'],
            ['Appointment desk', 'Booking help', 'Need to change your appointment? Send us the details and we will assist you.'],
            ['Billing team', 'Invoice question', 'Your billing messages and payment updates will appear in this inbox.'],
        ];

        foreach ($samples as $sample) {
            [$sender, $subject, $body] = $sample;
            $seedStmt->bind_param('isss', $userId, $sender, $subject, $body);
            $seedStmt->execute();
        }

        $seedStmt->close();
    }
}

$stmt = $conn->prepare(
    'SELECT id, user_id, sender, subject, body, is_read, created_at
     FROM messages
     WHERE user_id = ?
     ORDER BY is_read ASC, created_at DESC'
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

$stmt->bind_param('i', $userId);
$stmt->execute();
$result = $stmt->get_result();
$messages = [];

while ($row = $result->fetch_assoc()) {
    $row['id'] = intval($row['id']);
    $row['user_id'] = intval($row['user_id']);
    $row['is_read'] = intval($row['is_read']);
    $messages[] = $row;
}

echo json_encode([
    'success' => true,
    'message' => 'Messages loaded successfully.',
    'data' => $messages,
]);

$stmt->close();
$conn->close();
?>
