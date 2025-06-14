<?php

require_once '../bootstrap.php'; // Load bootstrap for Config and other includes

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (!isset($data['email']) || !isset($data['password']) || !isset($data['userType'])) {
    sendJsonResponse(false, 'Missing required fields');
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
$password = $data['password'];
$userType = $data['userType'];

// Additional fields based on user type
$companyName = $data['companyName'] ?? null;
$industry = $data['industry'] ?? null;
$startupName = $data['startupName'] ?? null;
$stage = $data['stage'] ?? null;
$fullName = $data['fullName'] ?? null;
$skills = $data['skills'] ?? null;

// Get database connection from bootstrap
$db = $database->getConnection();

try {
    // Check if email already exists
    $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->rowCount() > 0) {
        sendJsonResponse(false, 'Email already registered');
    }

    // Generate verification token
    $verificationToken = generateToken(Config::get('security.token_length'));
    $hashedPassword = password_hash($password, Config::get('security.password_hash_algo'), Config::get('security.password_hash_options'));

    // Insert user
    $stmt = $db->prepare("
        INSERT INTO users (email, password, user_type, verification_token, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ");
    $stmt->execute([$email, $hashedPassword, $userType, $verificationToken]);
    $userId = $db->lastInsertId();

    // Insert user-specific data
    switch ($userType) {
        case 'company': // Changed from 'Established Company' to match frontend dropdown
            $stmt = $db->prepare("
                INSERT INTO company_profiles (user_id, company_name, industry)
                VALUES (?, ?, ?)
            ");
            $stmt->execute([$userId, $companyName, $industry]);
            break;
        case 'startup': // Changed from 'Startup'
            $stmt = $db->prepare("
                INSERT INTO startup_profiles (user_id, startup_name, stage)
                VALUES (?, ?, ?)
            ");
            $stmt->execute([$userId, $startupName, $stage]);
            break;
        case 'seeker': // Changed from 'Job Seeker'
            $stmt = $db->prepare("
                INSERT INTO seeker_profiles (user_id, full_name, skills)
                VALUES (?, ?, ?)
            ");
            $stmt->execute([$userId, $fullName, $skills]);
            break;
    }

    // Send verification email
    $appUrl = Config::get('app.url');
    $verificationLink = "{$appUrl}/auth/verify.php?token=" . $verificationToken; // Use app.url
    $to = $email;
    $subject = "Verify your email address";
    $message = getVerificationEmailTemplate($verificationLink);

    if (!sendEmail($to, $subject, $message)) {
        // Optionally log the email sending failure
        error_log("Failed to send verification email to $to");
        sendJsonResponse(false, 'Registration successful, but failed to send verification email.');
    }

    sendJsonResponse(true, 'Registration successful. Please check your email for verification.', ['userId' => $userId]);

} catch (Exception $e) {
    sendJsonResponse(false, 'Registration failed: ' . $e->getMessage());
}
?> 