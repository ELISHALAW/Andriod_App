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

$createTableSql = "CREATE TABLE IF NOT EXISTS appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(120) NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    notes TEXT NULL,
    client_name VARCHAR(120) NULL,
    client_email VARCHAR(180) NULL,
    client_phone VARCHAR(50) NULL,
    client_age VARCHAR(20) NULL,
    client_gender VARCHAR(20) NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'confirmed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX (user_id)
)";

if (!$conn->query($createTableSql)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to prepare appointments table: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$stmt = $conn->prepare(
    'SELECT id, user_id, title, appointment_date, TIME_FORMAT(appointment_time, "%H:%i") AS appointment_time, notes, client_name, client_email, client_phone, client_age, client_gender, status, created_at
     FROM appointments
     WHERE user_id = ?
     ORDER BY appointment_date ASC, appointment_time ASC'
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
$appointments = [];

while ($row = $result->fetch_assoc()) {
    $row['id'] = intval($row['id']);
    $row['user_id'] = intval($row['user_id']);
    $appointments[] = $row;
}

echo json_encode([
    'success' => true,
    'message' => 'Appointments loaded successfully.',
    'data' => $appointments,
]);

$stmt->close();
$conn->close();
?>
