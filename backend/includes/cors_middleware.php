<?php
class CorsMiddleware {
    /**
     * Handle CORS preflight requests
     * 
     * @return void
     */
    public static function handlePreflight() {
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            self::setCorsHeaders();
            exit;
        }
    }

    /**
     * Set CORS headers for the response
     * 
     * @return void
     */
    public static function setCorsHeaders() {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
        $allowedOrigins = Config::get('cors.allowed_origins', ['http://localhost:3000']);
        
        if (in_array($origin, $allowedOrigins)) {
            header('Access-Control-Allow-Origin: ' . $origin);
        }

        header('Access-Control-Allow-Methods: ' . implode(', ', Config::get('cors.allowed_methods', ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])));
        header('Access-Control-Allow-Headers: ' . implode(', ', Config::get('cors.allowed_headers', ['Content-Type', 'Authorization', 'X-Requested-With'])));
        header('Access-Control-Allow-Credentials: ' . (Config::get('cors.allow_credentials', true) ? 'true' : 'false'));
        header('Access-Control-Max-Age: ' . Config::get('cors.max_age', 86400));

        $exposedHeaders = Config::get('cors.exposed_headers', []);
        if (!empty($exposedHeaders)) {
            header('Access-Control-Expose-Headers: ' . implode(', ', $exposedHeaders));
        }
    }

    /**
     * Check if the request origin is allowed
     * 
     * @return bool
     */
    public static function isAllowedOrigin() {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
        $allowedOrigins = Config::get('cors.allowed_origins', ['http://localhost:3000']);
        
        return in_array($origin, $allowedOrigins);
    }

    /**
     * Send CORS error response
     * 
     * @return void
     */
    public static function sendCorsError() {
        header('HTTP/1.1 403 Forbidden');
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'CORS error: Origin not allowed'
        ]);
        exit;
    }
}

// Handle CORS for all requests
CorsMiddleware::handlePreflight();
CorsMiddleware::setCorsHeaders();
?> 