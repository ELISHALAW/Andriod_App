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

$email = trim($input['email'] ?? '');
if ($email === '') {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Email is required.',
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

$token = bin2hex(random_bytes(32));
$tokenHash = hash('sha256', $token);
$expiresAt = gmdate('Y-m-d H:i:s', time() + 3600);

$lookupStmt = $conn->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
if (!$lookupStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$lookupStmt->bind_param('s', $email);
$lookupStmt->execute();
$lookupStmt->store_result();

if ($lookupStmt->num_rows > 0) {
    $lookupStmt->bind_result($userId);
    $lookupStmt->fetch();

    $insertStmt = $conn->prepare(
        'INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES (?, ?, ?)'
    );

    if (!$insertStmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create reset token.',
            'data' => null,
        ]);
        $lookupStmt->close();
        $conn->close();
        exit();
    }

    $insertStmt->bind_param('iss', $userId, $tokenHash, $expiresAt);
    if (!$insertStmt->execute()) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to save reset token.',
            'data' => null,
        ]);
        $insertStmt->close();
        $lookupStmt->close();
        $conn->close();
        exit();
    }

    $insertStmt->close();
}

$lookupStmt->close();
$conn->close();

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'If the email exists, a reset token has been generated.',
    'data' => [
        // Temporary manual-flow support. Replace with email/deep-link delivery in production.
        'reset_token' => $token,
        'expires_in_minutes' => 60,
    ],
]);
?>
