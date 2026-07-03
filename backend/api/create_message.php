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
$sender = trim($input['sender'] ?? '');
$subject = trim($input['subject'] ?? '');
$body = trim($input['body'] ?? '');

$errors = [];
if ($userId <= 0) $errors[] = 'User ID is required.';
if ($sender === '') $errors[] = 'Sender is required.';
if ($subject === '') $errors[] = 'Subject is required.';
if ($body === '') $errors[] = 'Message body is required.';

if (!empty($errors)) {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Validation failed.',
        'errors' => $errors,
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

$stmt = $conn->prepare(
    'INSERT INTO messages (user_id, sender, subject, body) VALUES (?, ?, ?, ?)'
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

$stmt->bind_param('isss', $userId, $sender, $subject, $body);
if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to create message: ' . $stmt->error,
        'data' => null,
    ]);
    $stmt->close();
    $conn->close();
    exit();
}

http_response_code(201);
echo json_encode([
    'success' => true,
    'message' => 'Message created successfully.',
    'data' => ['id' => $stmt->insert_id],
]);

$stmt->close();
$conn->close();
?>
