<?php
require_once 'db_connect.php';

class AuthMiddleware {
    private $db;
    private $user;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * Authenticate the request using the session token
     * 
     * @return bool
     */
    public function authenticate() {
        // Get the Authorization header
        $headers = getallheaders();
        $auth_header = isset($headers['Authorization']) ? $headers['Authorization'] : '';
        
        if (empty($auth_header) || !preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
            $this->sendUnauthorizedResponse('No token provided');
            return false;
        }

        $token = $matches[1];
        
        // Validate token
        $stmt = $this->db->prepare("
            SELECT u.*, s.expires_at 
            FROM users u 
            JOIN sessions s ON u.id = s.user_id 
            WHERE s.token = ? AND s.expires_at > NOW()
        ");
        
        $stmt->execute([$token]);
        $user = $stmt->fetch();

        if (!$user) {
            $this->sendUnauthorizedResponse('Invalid or expired token');
            return false;
        }

        // Store user data
        $this->user = $user;
        return true;
    }

    /**
     * Get the authenticated user's data
     * 
     * @return array|null
     */
    public function getUser() {
        return $this->user;
    }

    /**
     * Check if the authenticated user has a specific role
     * 
     * @param string $role Role to check
     * @return bool
     */
    public function hasRole($role) {
        return $this->user && $this->user['user_type'] === $role;
    }

    /**
     * Send unauthorized response
     * 
     * @param string $message Error message
     */
    private function sendUnauthorizedResponse($message) {
        header('HTTP/1.1 401 Unauthorized');
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => $message
        ]);
        exit;
    }

    /**
     * Require authentication for the current request
     * 
     * @return array User data
     */
    public static function requireAuth() {
        $middleware = new self();
        if (!$middleware->authenticate()) {
            exit; // Response already sent by authenticate()
        }
        return $middleware->getUser();
    }

    /**
     * Require specific role for the current request
     * 
     * @param string $role Required role
     * @return array User data
     */
    public static function requireRole($role) {
        $middleware = new self();
        if (!$middleware->authenticate()) {
            exit; // Response already sent by authenticate()
        }
        
        if (!$middleware->hasRole($role)) {
            header('HTTP/1.1 403 Forbidden');
            header('Content-Type: application/json');
            echo json_encode([
                'success' => false,
                'message' => 'Insufficient permissions'
            ]);
            exit;
        }
        
        return $middleware->getUser();
    }
}
?> 