<?php

require_once '../bootstrap.php'; // Load bootstrap for Config and other includes

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (!isset($data['email']) || !isset($data['password'])) {
    sendJsonResponse(false, 'Missing email or password');
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
$password = $data['password'];
$userType = $data['userType'] ?? null; // Assuming userType can be passed for specific login flows

// Get database connection from bootstrap
$db = $database->getConnection();

try {
    // Get user
    $stmt = $db->prepare("
        SELECT id, email, password, user_type, is_verified, verification_token
        FROM users
        WHERE email = ?
    ");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user) {
        sendJsonResponse(false, 'Invalid email or password');
    }

    // Verify password
    if (!password_verify($password, $user['password'])) {
        sendJsonResponse(false, 'Invalid email or password');
    }

    // Check if email is verified
    if (!$user['is_verified']) {
        sendJsonResponse(false, 'Please verify your email first', ['needsVerification' => true]);
    }

    // If a specific userType is provided, ensure it matches
    if ($userType && $user['user_type'] !== $userType) {
        sendJsonResponse(false, 'Invalid user type for this login');
    }

    // Generate session token
    $sessionToken = generateToken(Config::get('security.token_length'));
    
    // Store session
    $stmt = $db->prepare("
        INSERT INTO sessions (user_id, token, created_at, expires_at)
        VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? SECOND))
    ");
    $stmt->execute([$user['id'], $sessionToken, Config::get('jwt.expiration')]);

    // Get user profile based on user type
    $profile = [];
    switch ($user['user_type']) {
        case 'company':
            $stmt = $db->prepare("SELECT company_name, industry FROM company_profiles WHERE user_id = ?");
            $stmt->execute([$user['id']]);
            $profile = $stmt->fetch();
            break;
        case 'startup':
            $stmt = $db->prepare("SELECT startup_name, stage FROM startup_profiles WHERE user_id = ?");
            $stmt->execute([$user['id']]);
            $profile = $stmt->fetch();
            break;
        case 'seeker':
            $stmt = $db->prepare("SELECT full_name, skills FROM seeker_profiles WHERE user_id = ?");
            $stmt->execute([$user['id']]);
            $profile = $stmt->fetch();
            break;
    }

    sendJsonResponse(true, 'Login successful', [
        'token' => $sessionToken,
        'user' => [
            'id' => $user['id'],
            'email' => $user['email'],
            'userType' => $user['user_type'],
            'profile' => $profile
        ]
    ]);

} catch (Exception $e) {
    sendJsonResponse(false, 'Login failed: ' . $e->getMessage());
}
?> 