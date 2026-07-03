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

$name = trim($input['name'] ?? '');
$email = trim($input['email'] ?? '');
$phone = trim($input['phone_number'] ?? '');
$address = trim($input['address'] ?? '');
$password = $input['password'] ?? '';

$errors = [];
if ($name === '') $errors[] = 'Name is required.';
if ($email === '') $errors[] = 'Email is required.';
if ($phone === '') $errors[] = 'Phone number is required.';
if ($address === '') $errors[] = 'Address is required.';
if ($password === '') $errors[] = 'Password is required.';
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

$emailCheckStmt = $conn->prepare('SELECT id FROM users WHERE email = ?');
if (!$emailCheckStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$emailCheckStmt->bind_param('s', $email);
$emailCheckStmt->execute();
$emailCheckStmt->store_result();
if ($emailCheckStmt->num_rows > 0) {
    http_response_code(409);
    echo json_encode([
        'success' => false,
        'message' => 'Email already exists.',
        'data' => null,
    ]);
    $emailCheckStmt->close();
    $conn->close();
    exit();
}
$emailCheckStmt->close();

$hashedPassword = password_hash($password, PASSWORD_DEFAULT);
$insertStmt = $conn->prepare(
    'INSERT INTO users (name, email, phone_number, address, password) VALUES (?, ?, ?, ?, ?)'
);
if (!$insertStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$insertStmt->bind_param('sssss', $name, $email, $phone, $address, $hashedPassword);
if ($insertStmt->execute()) {
    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'User registered successfully.',
        'data' => ['id' => $insertStmt->insert_id],
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Registration failed: ' . $insertStmt->error,
        'data' => null,
    ]);
}

$insertStmt->close();
$conn->close();
?>