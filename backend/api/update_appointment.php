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

$appointmentId = isset($input['id']) ? intval($input['id']) : 0;
$userId = isset($input['user_id']) ? intval($input['user_id']) : 0;
$title = trim($input['title'] ?? '');
$appointmentDate = trim($input['appointment_date'] ?? '');
$appointmentTime = trim($input['appointment_time'] ?? '');
$notes = trim($input['notes'] ?? '');
$clientName = trim($input['client_name'] ?? '');
$clientEmail = trim($input['client_email'] ?? '');
$clientPhone = trim($input['client_phone'] ?? '');
$clientAge = trim($input['client_age'] ?? '');
$clientGender = trim($input['client_gender'] ?? '');

$errors = [];
if ($appointmentId <= 0) $errors[] = 'Appointment ID is required.';
if ($userId <= 0) $errors[] = 'User ID is required.';
if ($title === '') $errors[] = 'Title is required.';
if ($appointmentDate === '') $errors[] = 'Appointment date is required.';
if ($appointmentTime === '') $errors[] = 'Appointment time is required.';

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

$appointmentsTableSql = "CREATE TABLE IF NOT EXISTS appointments (
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

if (!$conn->query($appointmentsTableSql)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to prepare appointments table: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$updateStmt = $conn->prepare(
    'UPDATE appointments
     SET title = ?, appointment_date = ?, appointment_time = ?, notes = ?, client_name = ?, client_email = ?, client_phone = ?, client_age = ?, client_gender = ?, updated_at = CURRENT_TIMESTAMP
     WHERE id = ? AND user_id = ?
     LIMIT 1'
);

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

$updateStmt->bind_param(
    'sssssssssii',
    $title,
    $appointmentDate,
    $appointmentTime,
    $notes,
    $clientName,
    $clientEmail,
    $clientPhone,
    $clientAge,
    $clientGender,
    $appointmentId,
    $userId
);

if (!$updateStmt->execute()) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to update appointment: ' . $updateStmt->error,
        'data' => null,
    ]);
    $updateStmt->close();
    $conn->close();
    exit();
}

$updateStmt->close();

$selectStmt = $conn->prepare(
    'SELECT id, user_id, title, appointment_date, TIME_FORMAT(appointment_time, "%H:%i") AS appointment_time, notes, client_name, client_email, client_phone, client_age, client_gender, status, created_at
     FROM appointments
     WHERE id = ? AND user_id = ?
     LIMIT 1'
);

if (!$selectStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Appointment updated, but reload failed: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$selectStmt->bind_param('ii', $appointmentId, $userId);
$selectStmt->execute();
$result = $selectStmt->get_result();
$appointment = $result->fetch_assoc();
$selectStmt->close();
$conn->close();

if (!$appointment) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'Appointment not found.',
        'data' => null,
    ]);
    exit();
}

$appointment['id'] = intval($appointment['id']);
$appointment['user_id'] = intval($appointment['user_id']);

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Appointment updated successfully.',
    'data' => $appointment,
]);
?>
