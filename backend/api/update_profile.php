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
$name = trim($input['name'] ?? '');
$email = trim($input['email'] ?? '');
$phone = trim($input['phone_number'] ?? '');
$address = trim($input['address'] ?? '');
$profileImage = isset($input['profile_image']) ? trim($input['profile_image']) : null;

$errors = [];
if ($userId <= 0) $errors[] = 'User ID is required.';
if ($name === '') $errors[] = 'Name is required.';
if ($email === '') $errors[] = 'Email is required.';
if ($phone === '') $errors[] = 'Phone number is required.';
if ($address === '') $errors[] = 'Address is required.';

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

$emailCheckStmt = $conn->prepare('SELECT id FROM users WHERE email = ? AND id != ?');
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

$emailCheckStmt->bind_param('si', $email, $userId);
$emailCheckStmt->execute();
$emailCheckStmt->store_result();
if ($emailCheckStmt->num_rows > 0) {
    http_response_code(409);
    echo json_encode([
        'success' => false,
        'message' => 'Email is already used by another account.',
        'data' => null,
    ]);
    $emailCheckStmt->close();
    $conn->close();
    exit();
}
$emailCheckStmt->close();

$updateSql = $profileImage !== null && $profileImage !== ''
    ? 'UPDATE users SET name = ?, email = ?, phone_number = ?, address = ?, profile_image = ? WHERE id = ?'
    : 'UPDATE users SET name = ?, email = ?, phone_number = ?, address = ? WHERE id = ?';

$updateStmt = $conn->prepare($updateSql);
if (!$updateStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$effectiveImage = null;
if ($profileImage !== null && $profileImage !== '') {
    $effectiveImage = $profileImage;
    $updateStmt->bind_param('sssssi', $name, $email, $phone, $address, $effectiveImage, $userId);
} else {
    $currentImageStmt = $conn->prepare('SELECT profile_image FROM users WHERE id = ? LIMIT 1');
    if ($currentImageStmt) {
        $currentImageStmt->bind_param('i', $userId);
        $currentImageStmt->execute();
        $currentImageStmt->bind_result($existingImage);
        if ($currentImageStmt->fetch()) {
            $effectiveImage = $existingImage;
        }
        $currentImageStmt->close();
    }

    $updateStmt->bind_param('ssssi', $name, $email, $phone, $address, $userId);
}
if ($updateStmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Profile updated successfully.',
        'data' => [
            'id' => $userId,
            'name' => $name,
            'email' => $email,
            'phone_number' => $phone,
            'address' => $address,
            'profile_image' => $effectiveImage,
        ],
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Update failed: ' . $updateStmt->error,
        'data' => null,
    ]);
}

$updateStmt->close();
$conn->close();
?>