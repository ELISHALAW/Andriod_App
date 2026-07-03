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

$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';

if ($email === '' || $password === '') {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Email and password are required.',
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

$stmt = $conn->prepare('SELECT id, name, password FROM users WHERE email = ? LIMIT 1');
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

$stmt->bind_param('s', $email);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows === 0) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid email or password.',
        'data' => null,
    ]);
    $stmt->close();
    $conn->close();
    exit();
}

$stmt->bind_result($id, $name, $hashedPassword);
$stmt->fetch();

if (!password_verify($password, $hashedPassword)) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid email or password.',
        'data' => null,
    ]);
    $stmt->close();
    $conn->close();
    exit();
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Login successful.',
    'data' => [
        'id' => $id,
        'name' => $name,
        'email' => $email,
    ],
]);

$stmt->close();
$conn->close();
?>