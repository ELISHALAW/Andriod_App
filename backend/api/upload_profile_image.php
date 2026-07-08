<?php
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
$fileName = trim($input['file_name'] ?? '');
$fileContentBase64 = trim($input['file_content_base64'] ?? '');

$errors = [];
if ($userId <= 0) $errors[] = 'User ID is required.';
if ($fileName === '') $errors[] = 'File name is required.';
if ($fileContentBase64 === '') $errors[] = 'File content is required.';

$extension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
$allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
if (!in_array($extension, $allowedExtensions, true)) {
    $errors[] = 'Only JPG, PNG, or WEBP images are allowed.';
}

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

$decodedBytes = base64_decode($fileContentBase64, true);
if ($decodedBytes === false || strlen($decodedBytes) === 0) {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid file content.',
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

$userStmt = $conn->prepare('SELECT id, profile_image FROM users WHERE id = ? LIMIT 1');
if (!$userStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$userStmt->bind_param('i', $userId);
$userStmt->execute();
$userStmt->store_result();

if ($userStmt->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'User not found.',
        'data' => null,
    ]);
    $userStmt->close();
    $conn->close();
    exit();
}

$userStmt->bind_result($foundId, $existingImagePath);
$userStmt->fetch();
$userStmt->close();

$profilesDir = __DIR__ . '/uploads/profiles';
if (!is_dir($profilesDir) && !mkdir($profilesDir, 0777, true)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to prepare profile uploads directory.',
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$safeBase = preg_replace('/[^A-Za-z0-9_\-]/', '_', pathinfo($fileName, PATHINFO_FILENAME));
if ($safeBase === null || $safeBase === '') {
    $safeBase = 'avatar';
}

$storedName = 'user_' . $userId . '_' . time() . '_' . substr(md5($fileName . microtime()), 0, 8) . '.' . $extension;
$storedFilePath = $profilesDir . '/' . $storedName;

if (file_put_contents($storedFilePath, $decodedBytes) === false) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to save profile image.',
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$relativePath = 'uploads/profiles/' . $storedName;
$updateStmt = $conn->prepare('UPDATE users SET profile_image = ? WHERE id = ?');
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

$updateStmt->bind_param('si', $relativePath, $userId);
if (!$updateStmt->execute()) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to update profile image path: ' . $updateStmt->error,
        'data' => null,
    ]);
    $updateStmt->close();
    $conn->close();
    exit();
}
$updateStmt->close();

if (!empty($existingImagePath)) {
    $oldPath = __DIR__ . '/' . ltrim($existingImagePath, '/');
    if (is_file($oldPath)) {
        @unlink($oldPath);
    }
}

http_response_code(201);
echo json_encode([
    'success' => true,
    'message' => 'Profile image updated successfully.',
    'data' => [
        'profile_image' => $relativePath,
    ],
]);

$conn->close();
?>