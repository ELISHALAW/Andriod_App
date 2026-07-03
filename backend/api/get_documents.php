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

$createTableSql = "CREATE TABLE IF NOT EXISTS documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(120) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(180) NOT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (user_id)
)";

if (!$conn->query($createTableSql)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to prepare documents table: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$countStmt = $conn->prepare('SELECT COUNT(*) FROM documents WHERE user_id = ?');
if (!$countStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'data' => null,
    ]);
    $conn->close();
    exit();
}

$countStmt->bind_param('i', $userId);
$countStmt->execute();
$countStmt->bind_result($count);
$countStmt->fetch();
$countStmt->close();

if ($count === 0) {
    $seedStmt = $conn->prepare(
        'INSERT INTO documents (user_id, title, document_type, file_name, notes) VALUES (?, ?, ?, ?, ?)'
    );

    if ($seedStmt) {
        $samples = [
            ['Appointment Receipt', 'Receipt', 'appointment_receipt.pdf', 'Sample receipt for your latest booking.'],
            ['Monthly Invoice', 'Invoice', 'monthly_invoice.pdf', 'Payment document for account billing.'],
            ['Profile Form', 'Form', 'profile_update_form.pdf', 'Form for keeping profile details current.'],
        ];

        foreach ($samples as $sample) {
            [$title, $documentType, $fileName, $notes] = $sample;
            $seedStmt->bind_param('issss', $userId, $title, $documentType, $fileName, $notes);
            $seedStmt->execute();
        }

        $seedStmt->close();
    }
}

$stmt = $conn->prepare(
    'SELECT id, user_id, title, document_type, file_name, notes, created_at
     FROM documents
     WHERE user_id = ?
     ORDER BY created_at DESC'
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
$documents = [];

while ($row = $result->fetch_assoc()) {
    $row['id'] = intval($row['id']);
    $row['user_id'] = intval($row['user_id']);
    $documents[] = $row;
}

echo json_encode([
    'success' => true,
    'message' => 'Documents loaded successfully.',
    'data' => $documents,
]);

$stmt->close();
$conn->close();
?>
