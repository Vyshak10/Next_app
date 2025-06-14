<?php

require_once '../bootstrap.php'; // Load bootstrap for Config and other includes

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['email'])) {
    sendJsonResponse(false, 'Email is required');
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);

// Get database connection from bootstrap
$db = $database->getConnection();

try {
    // Check if user exists and is not verified
    $stmt = $db->prepare("
        SELECT id, email, verification_token, is_verified 
        FROM users 
        WHERE email = ?
    ");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user) {
        sendJsonResponse(false, 'No account found with this email');
    }

    if ($user['is_verified']) {
        sendJsonResponse(false, 'Email is already verified');
    }

    // Generate new verification token
    $verificationToken = generateToken(Config::get('security.token_length'));

    // Update user with new token
    $stmt = $db->prepare("
        UPDATE users 
        SET verification_token = ?,
            updated_at = NOW()
        WHERE id = ?
    ");
    $stmt->execute([$verificationToken, $user['id']]);

    // Send verification email
    $appUrl = Config::get('app.url');
    $verificationLink = "{$appUrl}/auth/verify.php?token=" . $verificationToken; // Use app.url
    $to = $email;
    $subject = "Verify your email address";
    $message = getVerificationEmailTemplate($verificationLink);

    if (!sendEmail($to, $subject, $message)) {
        error_log("Failed to resend verification email to $to");
        sendJsonResponse(false, 'Failed to send verification email. Please try again.');
    }

    sendJsonResponse(true, 'Verification email sent successfully.');

} catch (Exception $e) {
    sendJsonResponse(false, 'Resend verification failed: ' . $e->getMessage());
}
?> 