<?php
require_once 'db_connect.php';

class RateLimiter {
    private $db;
    private $ip;
    private $endpoint;
    private $maxAttempts;
    private $decayMinutes;

    public function __construct($endpoint) {
        $database = new Database();
        $this->db = $database->getConnection();
        
        $this->ip = $_SERVER['REMOTE_ADDR'];
        $this->endpoint = $endpoint;
        $this->maxAttempts = Config::get('rate_limit.max_attempts', 60);
        $this->decayMinutes = Config::get('rate_limit.decay_minutes', 1);
    }

    /**
     * Check if the request should be rate limited
     * 
     * @return bool
     */
    public function tooManyAttempts() {
        if (!Config::get('rate_limit.enabled', true)) {
            return false;
        }

        $this->cleanup();
        
        $stmt = $this->db->prepare("
            SELECT COUNT(*) as attempts 
            FROM rate_limits 
            WHERE ip = ? AND endpoint = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? MINUTE)
        ");
        
        $stmt->execute([$this->ip, $this->endpoint, $this->decayMinutes]);
        $result = $stmt->fetch();
        
        return $result['attempts'] >= $this->maxAttempts;
    }

    /**
     * Increment the rate limit counter
     * 
     * @return void
     */
    public function hit() {
        if (!Config::get('rate_limit.enabled', true)) {
            return;
        }

        $stmt = $this->db->prepare("
            INSERT INTO rate_limits (ip, endpoint, created_at) 
            VALUES (?, ?, NOW())
        ");
        
        $stmt->execute([$this->ip, $this->endpoint]);
    }

    /**
     * Get the number of remaining attempts
     * 
     * @return int
     */
    public function remainingAttempts() {
        if (!Config::get('rate_limit.enabled', true)) {
            return $this->maxAttempts;
        }

        $stmt = $this->db->prepare("
            SELECT COUNT(*) as attempts 
            FROM rate_limits 
            WHERE ip = ? AND endpoint = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? MINUTE)
        ");
        
        $stmt->execute([$this->ip, $this->endpoint, $this->decayMinutes]);
        $result = $stmt->fetch();
        
        return max(0, $this->maxAttempts - $result['attempts']);
    }

    /**
     * Get the time until the rate limit resets
     * 
     * @return int
     */
    public function availableIn() {
        if (!Config::get('rate_limit.enabled', true)) {
            return 0;
        }

        $stmt = $this->db->prepare("
            SELECT MAX(created_at) as last_attempt 
            FROM rate_limits 
            WHERE ip = ? AND endpoint = ?
        ");
        
        $stmt->execute([$this->ip, $this->endpoint]);
        $result = $stmt->fetch();
        
        if (!$result['last_attempt']) {
            return 0;
        }

        $lastAttempt = strtotime($result['last_attempt']);
        $resetTime = $lastAttempt + ($this->decayMinutes * 60);
        $now = time();
        
        return max(0, $resetTime - $now);
    }

    /**
     * Clean up expired rate limit records
     * 
     * @return void
     */
    private function cleanup() {
        $stmt = $this->db->prepare("
            DELETE FROM rate_limits 
            WHERE created_at < DATE_SUB(NOW(), INTERVAL ? MINUTE)
        ");
        
        $stmt->execute([$this->decayMinutes]);
    }

    /**
     * Send rate limit exceeded response
     * 
     * @return void
     */
    public function sendRateLimitExceededResponse() {
        header('HTTP/1.1 429 Too Many Requests');
        header('Content-Type: application/json');
        header('Retry-After: ' . $this->availableIn());
        
        echo json_encode([
            'success' => false,
            'message' => 'Too many attempts. Please try again later.',
            'retry_after' => $this->availableIn()
        ]);
        
        exit;
    }
}

// Create rate_limits table if it doesn't exist
$database = new Database();
$db = $database->getConnection();

$db->exec("
    CREATE TABLE IF NOT EXISTS rate_limits (
        id INT AUTO_INCREMENT PRIMARY KEY,
        ip VARCHAR(45) NOT NULL,
        endpoint VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_ip_endpoint (ip, endpoint),
        INDEX idx_created_at (created_at)
    )
");
?> 