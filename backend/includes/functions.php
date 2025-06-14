<?php

require_once __DIR__ . '/config.php'; // Ensure Config is loaded

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// PHPMailer autoloader - Assuming PHPMailer is installed via Composer
// If not using Composer, you'll need to manually include PHPMailer files:
// require_once __DIR__ . '/path/to/PHPMailer/src/Exception.php';
// require_once __DIR__ . '/path/to/PHPMailer/src/PHPMailer.php';
// require_once __DIR__ . '/path/to/PHPMailer/src/SMTP.php';

/**
 * Send an email with HTML support using PHPMailer
 * 
 * @param string $to Recipient email
 * @param string $subject Email subject
 * @param string $message Email message (HTML supported)
 * @return bool
 */
function sendEmail($to, $subject, $message) {
    $mail = new PHPMailer(true);
    
    try {
        //Server settings
        $mail->isSMTP();                                            // Send using SMTP
        $mail->Host       = Config::get('mail.smtp.host');         // Set the SMTP server to send through
        $mail->SMTPAuth   = true;                                   // Enable SMTP authentication
        $mail->Username   = Config::get('mail.smtp.username');      // SMTP username
        $mail->Password   = Config::get('mail.smtp.password');      // SMTP password
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;         // Enable TLS encryption; `PHPMailer::ENCRYPTION_SMTPS` encouraged
        $mail->Port       = Config::get('mail.smtp.port');          // TCP port to connect to

        //Recipients
        $fromAddress = Config::get('mail.from.address', 'noreply@example.com');
        $fromName = Config::get('mail.from.name', 'App Name');
        $mail->setFrom($fromAddress, $fromName);
        $mail->addAddress($to);

        // Content
        $mail->isHTML(true);                                  // Set email format to HTML
        $mail->Subject = $subject;
        $mail->Body    = $message;
        $mail->AltBody = strip_tags($message); // Plain text for non-HTML mail clients

        $mail->send();
        return true;
    } catch (Exception $e) {
        // Log the error or handle it as appropriate
        error_log("Message could not be sent. Mailer Error: {$mail->ErrorInfo}");
        return false;
    }
}

/**
 * Generate a verification email template
 * 
 * @param string $verificationLink The verification link
 * @return string HTML email template
 */
function getVerificationEmailTemplate($verificationLink) {
    $appName = Config::get('app.name', 'NEXT');
    $appYear = date('Y');

    return '
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Verify Your Email</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .button { 
                display: inline-block; 
                padding: 12px 24px; 
                background-color: #007bff; 
                color: white; 
                text-decoration: none; 
                border-radius: 4px; 
                margin: 20px 0; 
            }
            .footer { 
                margin-top: 30px; 
                padding-top: 20px; 
                border-top: 1px solid #eee; 
                font-size: 12px; 
                color: #666; 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h2>Welcome to ' . $appName . '!</h2>
            <p>Thank you for registering. Please verify your email address by clicking the button below:</p>
            <a href="' . $verificationLink . '" class="button">Verify Email Address</a>
            <p>If the button above doesn\'t work, you can also copy and paste this link into your browser:</p>
            <p>' . $verificationLink . '</p>
            <p>This verification link will expire in 24 hours.</p>
            <div class="footer">
                <p>If you didn\'t create an account, you can safely ignore this email.</p>
                <p>&copy; ' . $appYear . ' ' . $appName . '. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>';
}

/**
 * Validate email format
 * 
 * @param string $email Email to validate
 * @return bool
 */
function isValidEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Generate a random token
 * 
 * @param int $length Token length
 * @return string
 */
function generateToken($length = 32) {
    return bin2hex(random_bytes($length));
}

/**
 * Sanitize input data
 * 
 * @param string $data Data to sanitize
 * @return string
 */
function sanitizeInput($data) {
    return htmlspecialchars(strip_tags(trim($data)));
}

/**
 * Check if a request is AJAX
 * 
 * @return bool
 */
function isAjaxRequest() {
    return !empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
           strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest';
}

/**
 * Send JSON response
 * 
 * @param bool $success Success status
 * @param string $message Response message
 * @param array $data Additional data
 */
function sendJsonResponse($success, $message, $data = []) {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}
?> 