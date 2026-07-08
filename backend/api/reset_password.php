<?php
// ====================== CORS & Headers ======================
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

mysqli_report(MYSQLI_REPORT_OFF);

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

$token = trim($input['token'] ?? '');
$newPassword = $input['new_password'] ?? '';

if ($token === '' || $newPassword === '') {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Token and new password are required.',
        'data' => null,
    ]);
    exit();
}

if (strlen($newPassword) < 6) {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Password must be at least 6 characters.',
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

$createTableSql = "CREATE TABLE IF NOT EXISTS password_resets (
    id INT(11) NOT NULL AUTO_INCREMENT,
    user_id INT(11) NOT NULL,
    token_hash CHAR(64) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY token_hash (token_hash),
    KEY user_id (user_id),
    KEY expires_at (expires_at),
    KEY used_at (used_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci";

if (!$conn->query($createTableSql)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to initialize password reset storage.',
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$tokenHash = hash('sha256', $token);

$findStmt = $conn->prepare(
    'SELECT user_id FROM password_resets WHERE token_hash = ? AND used_at IS NULL AND expires_at > UTC_TIMESTAMP() ORDER BY id DESC LIMIT 1'
);
if (!$findStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$findStmt->bind_param('s', $tokenHash);
$findStmt->execute();
$findStmt->store_result();

if ($findStmt->num_rows === 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid or expired token.',
        'data' => null,
    ]);
    $findStmt->close();
    $conn->close();
    exit();
}

$findStmt->bind_result($userId);
$findStmt->fetch();
$findStmt->close();

$newPasswordHash = password_hash($newPassword, PASSWORD_DEFAULT);

$conn->begin_transaction();

$updateUserStmt = $conn->prepare('UPDATE users SET password = ? WHERE id = ?');
$markUsedStmt = $conn->prepare('UPDATE password_resets SET used_at = UTC_TIMESTAMP() WHERE user_id = ? AND used_at IS NULL');

if (!$updateUserStmt || !$markUsedStmt) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error while preparing reset.',
        'data' => null,
    ]);
    if ($updateUserStmt) $updateUserStmt->close();
    if ($markUsedStmt) $markUsedStmt->close();
    $conn->close();
    exit();
}

$updateUserStmt->bind_param('si', $newPasswordHash, $userId);
$markUsedStmt->bind_param('i', $userId);

$userUpdated = $updateUserStmt->execute();
$tokenMarked = $markUsedStmt->execute();

if ($userUpdated && $tokenMarked) {
    $conn->commit();
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Password reset successful. Please log in with your new password.',
        'data' => null,
    ]);
} else {
    $conn->rollback();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Password reset failed. Please try again.',
        'data' => null,
    ]);
}

$updateUserStmt->close();
$markUsedStmt->close();
$conn->close();
?>
