<?php

require_once '../bootstrap.php'; // Load bootstrap for Config and other includes

// Get token from URL
$token = $_GET['token'] ?? '';

if (empty($token)) {
    sendJsonResponse(false, 'Verification token is required');
}

// Get database connection from bootstrap
$db = $database->getConnection();

try {
    // Find user with this token
    $stmt = $db->prepare("
        SELECT id, email, is_verified 
        FROM users 
        WHERE verification_token = ? AND is_verified = 0
    ");
    $stmt->execute([$token]);
    $user = $stmt->fetch();

    if (!$user) {
        sendJsonResponse(false, 'Invalid or expired verification token');
    }

    // Update user verification status
    $stmt = $db->prepare("
        UPDATE users 
        SET is_verified = 1, 
            verification_token = NULL,
            updated_at = NOW()
        WHERE id = ?
    ");
    $stmt->execute([$user['id']]);

    sendJsonResponse(true, 'Email verified successfully. You can now login.');

} catch (Exception $e) {
    sendJsonResponse(false, 'Verification failed: ' . $e->getMessage());
}
?> 