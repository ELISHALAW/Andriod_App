<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Use GET.',
        'data' => null,
    ]);
    exit();
}

$fileParam = isset($_GET['file']) ? trim($_GET['file']) : '';
$modeParam = isset($_GET['mode']) ? trim($_GET['mode']) : 'inline';

if ($fileParam === '') {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'message' => 'Missing file name.',
        'data' => null,
    ]);
    exit();
}

$safeFileName = basename($fileParam);
$extension = strtolower(pathinfo($safeFileName, PATHINFO_EXTENSION));
$allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];

if (!in_array($extension, $allowedExtensions, true)) {
    http_response_code(422);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'message' => 'Unsupported file type.',
        'data' => null,
    ]);
    exit();
}

$filePath = __DIR__ . '/uploads/' . $safeFileName;
if (!is_file($filePath)) {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'message' => 'File not found.',
        'data' => null,
    ]);
    exit();
}

$mimeType = mime_content_type($filePath);
if (!$mimeType) {
    if ($extension === 'pdf') {
        $mimeType = 'application/pdf';
    } elseif ($extension === 'png') {
        $mimeType = 'image/png';
    } else {
        $mimeType = 'image/jpeg';
    }
}

$disposition = $modeParam === 'download' ? 'attachment' : 'inline';

header('Content-Type: ' . $mimeType);
header('Content-Length: ' . filesize($filePath));
header('Content-Disposition: ' . $disposition . '; filename="' . $safeFileName . '"');
header('Cache-Control: private, max-age=3600');

readfile($filePath);
exit();
?>