<?php
// ====================== CORS & Headers ======================
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');           // Change to your domain later
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request (important for Flutter Web)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ====================== Database Connection ======================
$host = 'localhost';
$db_user = 'root';
$db_pass = '';
$db_name = 'android_app';

try {
    $conn = new mysqli($host, $db_user, $db_pass, $db_name);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database connection failed: ' . $conn->connect_error,
            'data' => null
        ]);
        exit;
    }

    // Test query
    $result = $conn->query("SELECT 1 as connection_test");

    if ($result) {
        echo json_encode([
            'success' => true,
            'message' => 'MySQL connection successful!',
            'data' => [
                'host' => $host,
                'database' => $db_name,
                'connection_time' => date('Y-m-d H:i:s'),
                'mysql_version' => $conn->server_info
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Test query failed: ' . $conn->error,
            'data' => null
        ]);
    }

    $conn->close();

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Exception: ' . $e->getMessage(),
        'data' => null
    ]);
}
?>