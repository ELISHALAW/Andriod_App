<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// MySQL Connection Details
$host = 'localhost';
$db_user = 'root'; // Change to your MySQL username
$db_pass = ''; // Change to your MySQL password
$db_name = 'android_app';

try {
    // Create connection
    $conn = new mysqli($host, $db_user, $db_pass, $db_name);

    // Check connection
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
                'connection_time' => date('Y-m-d H:i:s')
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Query failed: ' . $conn->error,
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
