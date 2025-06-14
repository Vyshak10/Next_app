<?php
require_once '../bootstrap.php';

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (!isset($data['email'])) {
    sendJsonResponse(false, 'Email is required');
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);

// Get database connection from bootstrap
$db = $database->getConnection();

try {
    // Check if user exists (without revealing if email is registered)
    $stmt = $db->prepare("SELECT id, email, is_verified FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    // Always return success to prevent email enumeration attacks
    if (!$user || !$user['is_verified']) {
        sendJsonResponse(true, 'If an account with that email exists and is verified, a password reset link has been sent.');
    }

    // Generate a unique reset token
    $token = generateToken(Config::get('security.token_length'));
    $expiresAt = date('Y-m-d H:i:s', time() + Config::get('security.password_reset_token_expiry'));

    // Delete any existing tokens for this user
    $stmt = $db->prepare("DELETE FROM password_resets WHERE user_id = ?");
    $stmt->execute([$user['id']]);

    // Store the new token
    $stmt = $db->prepare("
        INSERT INTO password_resets (user_id, token, expires_at, created_at)
        VALUES (?, ?, ?, NOW())
    ");
    $stmt->execute([$user['id'], $token, $expiresAt]);

    // Send reset email
    $appUrl = Config::get('app.url');
    $resetLink = "{$appUrl}/auth/reset_password_view.php?token=" . $token; // Assuming you'll have a frontend view
    $subject = "Password Reset Request for " . Config::get('app.name');
    $message = "Please click the following link to reset your password: " . $resetLink;
    $message .= "<br><br>This link will expire in " . (Config::get('security.password_reset_token_expiry') / 60) . " minutes.";

    if (!sendEmail($user['email'], $subject, $message)) {
        error_log("Failed to send password reset email to {$user['email']}");
        // Still return success to avoid leaking info about email existence
        sendJsonResponse(true, 'If an account with that email exists and is verified, a password reset link has been sent.');
    }

    sendJsonResponse(true, 'If an account with that email exists and is verified, a password reset link has been sent.');

} catch (Exception $e) {
    // Log the actual error but return a generic message to the user for security
    error_log("Password reset request failed for email $email: " . $e->getMessage());
    sendJsonResponse(false, 'An error occurred while processing your request.');
}
?> 