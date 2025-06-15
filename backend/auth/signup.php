<?php

require_once '../bootstrap.php'; // Load bootstrap for Config and other includes

header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 1);

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Get raw POST data
$rawData = file_get_contents("php://input");

// Debug: log raw input (remove this in production)
file_put_contents('signup_debug.log', $rawData);

if (!$rawData || empty(trim($rawData))) {
    sendJsonResponse(false, 'No data received');
    exit;
}

$data = json_decode($rawData, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    sendJsonResponse(false, 'Invalid JSON data: ' . json_last_error_msg());
    exit;
}

// Required field checks
if (!isset($data['email'], $data['password'], $data['userType'])) {
    sendJsonResponse(false, 'Missing required fields');
    exit;
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendJsonResponse(false, 'Invalid email format');
    exit;
}

$password = $data['password'];
if (strlen($password) < 8 || !preg_match('/[A-Za-z]/', $password) || !preg_match('/[0-9]/', $password)) {
    sendJsonResponse(false, 'Password must be at least 8 characters long and contain both letters and numbers');
    exit;
}

$userType = strtolower(trim($data['userType']));
if (!in_array($userType, ['company', 'startup', 'seeker'])) {
    sendJsonResponse(false, 'Invalid user type');
    exit;
}

// Extract type-specific fields
switch ($userType) {
    case 'company':
        if (empty($data['companyName']) || empty($data['industry'])) {
            sendJsonResponse(false, 'Company name and industry are required');
            exit;
        }
        $companyName = trim($data['companyName']);
        $industry = trim($data['industry']);
        break;

    case 'startup':
        if (empty($data['startupName']) || empty($data['stage'])) {
            sendJsonResponse(false, 'Startup name and stage are required');
            exit;
        }
        $startupName = trim($data['startupName']);
        $stage = trim($data['stage']);
        break;

    case 'seeker':
        if (empty($data['fullName']) || empty($data['skills'])) {
            sendJsonResponse(false, 'Full name and skills are required');
            exit;
        }
        $fullName = trim($data['fullName']);
        $skills = trim($data['skills']);
        break;
}

$db = $database->getConnection();
if (!$db) {
    error_log("Database connection failed");
    sendJsonResponse(false, 'Database connection error');
    exit;
}

try {
    // Check for duplicate email
    $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->rowCount() > 0) {
        sendJsonResponse(false, 'Email already registered');
        exit;
    }

    $verificationToken = generateToken(Config::get('security.token_length'));
    $hashedPassword = password_hash($password, Config::get('security.password_hash_algo'), Config::get('security.password_hash_options'));

    $stmt = $db->prepare("
        INSERT INTO users (email, password, user_type, verification_token, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ");
    $stmt->execute([$email, $hashedPassword, $userType, $verificationToken]);
    $userId = $db->lastInsertId();

    // Insert user-type-specific profile
    switch ($userType) {
        case 'company':
            $stmt = $db->prepare("INSERT INTO company_profiles (user_id, company_name, industry) VALUES (?, ?, ?)");
            $stmt->execute([$userId, $companyName, $industry]);
            break;
        case 'startup':
            $stmt = $db->prepare("INSERT INTO startup_profiles (user_id, startup_name, stage) VALUES (?, ?, ?)");
            $stmt->execute([$userId, $startupName, $stage]);
            break;
        case 'seeker':
            $stmt = $db->prepare("INSERT INTO seeker_profiles (user_id, full_name, skills) VALUES (?, ?, ?)");
            $stmt->execute([$userId, $fullName, $skills]);
            break;
    }

    // Send verification email
    $verificationLink = Config::get('app.url') . "/auth/verify.php?token=$verificationToken";
    $to = $email;
    $subject = "Verify your email address";
    $message = getVerificationEmailTemplate($verificationLink);

    if (!sendEmail($to, $subject, $message)) {
        error_log("Failed to send verification email to $to");
        sendJsonResponse(true, 'Account created, but verification email failed.', [
            'userId' => $userId,
            'email' => $email,
            'userType' => $userType,
            'emailStatus' => 'failed'
        ]);
        exit;
    }

    sendJsonResponse(true, 'Account created successfully. Please check your email for verification.', [
        'userId' => $userId,
        'email' => $email,
        'userType' => $userType,
        'emailStatus' => 'sent'
    ]);
    exit;

} catch (PDOException $e) {
    error_log('Database Error: ' . $e->getMessage());
    sendJsonResponse(false, 'Database error occurred during registration.');
    exit;
} catch (Exception $e) {
    error_log('General Error: ' . $e->getMessage());
    sendJsonResponse(false, 'Unexpected error occurred.');
    exit;
}

?>
