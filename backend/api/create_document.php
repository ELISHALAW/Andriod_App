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
$title = trim($input['title'] ?? '');
$documentType = trim($input['document_type'] ?? '');
$fileName = trim($input['file_name'] ?? '');
$notes = trim($input['notes'] ?? '');

$errors = [];
if ($userId <= 0) $errors[] = 'User ID is required.';
if ($title === '') $errors[] = 'Title is required.';
if ($documentType === '') $errors[] = 'Document type is required.';
if ($fileName === '') $errors[] = 'File name is required.';

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

$documentsTableSql = "CREATE TABLE IF NOT EXISTS documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(120) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(180) NOT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (user_id)
)";

if (!$conn->query($documentsTableSql)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to prepare database tables: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$stmt = $conn->prepare(
    'INSERT INTO documents (user_id, title, document_type, file_name, notes) VALUES (?, ?, ?, ?, ?)'
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

$stmt->bind_param('issss', $userId, $title, $documentType, $fileName, $notes);
if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to create document: ' . $stmt->error,
        'data' => null,
    ]);
    $stmt->close();
    $conn->close();
    exit();
}

$documentId = $stmt->insert_id;
$stmt->close();

http_response_code(201);
echo json_encode([
    'success' => true,
    'message' => 'Document added successfully.',
    'data' => ['id' => $documentId],
]);

$conn->close();
?>
