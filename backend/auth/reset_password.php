<?php
require_once '../bootstrap.php';

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (!isset($data['token']) || !isset($data['password'])) {
    sendJsonResponse(false, 'Missing token or new password');
}

$token = $data['token'];
$newPassword = $data['password'];

// Get database connection from bootstrap
$db = $database->getConnection();

try {
    // Start transaction
    $db->beginTransaction();

    // Verify the reset token
    $stmt = $db->prepare("
        SELECT pr.user_id, u.email 
        FROM password_resets pr
        JOIN users u ON pr.user_id = u.id
        WHERE pr.token = ? AND pr.expires_at > NOW()
    ");
    $stmt->execute([$token]);
    $resetRequest = $stmt->fetch();

    if (!$resetRequest) {
        sendJsonResponse(false, 'Invalid or expired password reset token');
    }

    $userId = $resetRequest['user_id'];

    // Hash the new password
    $hashedPassword = password_hash($newPassword, Config::get('security.password_hash_algo'), Config::get('security.password_hash_options'));

    // Update user's password
    $stmt = $db->prepare("
        UPDATE users 
        SET password = ?, 
            updated_at = NOW()
        WHERE id = ?
    ");
    $stmt->execute([$hashedPassword, $userId]);

    // Invalidate the used token
    $stmt = $db->prepare("DELETE FROM password_resets WHERE user_id = ?");
    $stmt->execute([$userId]);

    // Invalidate all existing sessions for the user (optional, but good for security)
    $stmt = $db->prepare("DELETE FROM sessions WHERE user_id = ?");
    $stmt->execute([$userId]);

    // Commit transaction
    $db->commit();

    sendJsonResponse(true, 'Password has been reset successfully. You can now login with your new password.');

} catch (Exception $e) {
    // Rollback transaction on error
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    error_log("Password reset failed: " . $e->getMessage());
    sendJsonResponse(false, 'Failed to reset password: ' . $e->getMessage());
}
?> 