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

$userId = isset($input['id']) ? intval($input['id']) : 0;
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

$columnCheck = $conn->query("SHOW COLUMNS FROM users LIKE 'profile_image'");
if ($columnCheck && $columnCheck->num_rows === 0) {
    if (!$conn->query('ALTER TABLE users ADD COLUMN profile_image VARCHAR(255) NULL')) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to prepare users table: ' . $conn->error,
            'data' => null,
        ]);
        $conn->close();
        exit();
    }
}

$stmt = $conn->prepare('SELECT id, name, email, phone_number, address, profile_image FROM users WHERE id = ? LIMIT 1');
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
$stmt->store_result();

if ($stmt->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'User not found.',
        'data' => null,
    ]);
    $stmt->close();
    $conn->close();
    exit();
}

$stmt->bind_result($id, $name, $email, $phoneNumber, $address, $profileImage);
$stmt->fetch();

echo json_encode([
    'success' => true,
    'message' => 'Profile loaded successfully.',
    'data' => [
        'id' => $id,
        'name' => $name,
        'email' => $email,
        'phone_number' => $phoneNumber,
        'address' => $address,
        'profile_image' => $profileImage,
    ],
]);

$stmt->close();
$conn->close();
?>