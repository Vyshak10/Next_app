<?php
// Set timezone
date_default_timezone_set('UTC');

// Load configuration
require_once __DIR__ . '/config/app.php';
require_once __DIR__ . '/includes/config.php';

// Load error handler
require_once __DIR__ . '/includes/error_handler.php';

// Load database connection
require_once __DIR__ . '/includes/db_connect.php';

// Load helper functions
require_once __DIR__ . '/includes/functions.php';

// Load middleware
require_once __DIR__ . '/includes/cors_middleware.php';
require_once __DIR__ . '/includes/auth_middleware.php';
require_once __DIR__ . '/includes/rate_limiter.php';

// Load WebSocket notifier
require_once __DIR__ . '/includes/WebSocketNotifier.php';

// Create required directories
$directories = [
    __DIR__ . '/logs',
    __DIR__ . '/uploads/images',
    __DIR__ . '/uploads/videos',
    __DIR__ . '/uploads/documents'
];

foreach ($directories as $directory) {
    if (!is_dir($directory)) {
        mkdir($directory, 0777, true);
    }
}

// Set error reporting based on environment
if (Config::get('app.debug', false)) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// Set session configuration
ini_set('session.cookie_httponly', 1);
ini_set('session.use_only_cookies', 1);
ini_set('session.cookie_secure', isset($_SERVER['HTTPS']));

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Set default headers
header('Content-Type: application/json');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');

// Handle CORS
CorsMiddleware::handlePreflight();
CorsMiddleware::setCorsHeaders();

// Initialize WebSocket notifier
WebSocketNotifier::init(
    getenv('WS_SERVER_URL') ?: 'http://localhost:8080',
    getenv('JWT_SECRET') ?: 'your-secret-key'
);

// Initialize database tables
$database = new Database();
$db = $database->getConnection();

// Load and execute schema
$schema = file_get_contents(__DIR__ . '/database/schema.sql');
$db->exec($schema);

// Set up rate limiting
$endpoint = $_SERVER['REQUEST_URI'];
$rateLimiter = new RateLimiter($endpoint);

if ($rateLimiter->tooManyAttempts()) {
    $rateLimiter->sendRateLimitExceededResponse();
}

$rateLimiter->hit();

// Set error handler
set_error_handler('handleError');
set_exception_handler('handleException');

// Apply rate limiting
applyRateLimit();
?> 