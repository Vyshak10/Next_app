<?php
class ErrorHandler {
    /**
     * Initialize error handling
     * 
     * @return void
     */
    public static function init() {
        error_reporting(E_ALL);
        set_error_handler([self::class, 'handleError']);
        set_exception_handler([self::class, 'handleException']);
        register_shutdown_function([self::class, 'handleShutdown']);
    }

    /**
     * Handle PHP errors
     * 
     * @param int $errno Error number
     * @param string $errstr Error message
     * @param string $errfile File where error occurred
     * @param int $errline Line number where error occurred
     * @return bool
     */
    public static function handleError($errno, $errstr, $errfile, $errline) {
        if (!(error_reporting() & $errno)) {
            return false;
        }

        $error = [
            'type' => $errno,
            'message' => $errstr,
            'file' => $errfile,
            'line' => $errline
        ];

        self::logError($error);
        self::sendErrorResponse($error);

        return true;
    }

    /**
     * Handle uncaught exceptions
     * 
     * @param Throwable $exception The exception
     * @return void
     */
    public static function handleException($exception) {
        $error = [
            'type' => get_class($exception),
            'message' => $exception->getMessage(),
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
            'trace' => $exception->getTraceAsString()
        ];

        self::logError($error);
        self::sendErrorResponse($error);
    }

    /**
     * Handle fatal errors
     * 
     * @return void
     */
    public static function handleShutdown() {
        $error = error_get_last();
        
        if ($error !== null && in_array($error['type'], [E_ERROR, E_CORE_ERROR, E_COMPILE_ERROR, E_USER_ERROR])) {
            self::logError($error);
            self::sendErrorResponse($error);
        }
    }

    /**
     * Log error to file
     * 
     * @param array $error Error details
     * @return void
     */
    private static function logError($error) {
        $logDir = __DIR__ . '/../logs';
        if (!is_dir($logDir)) {
            mkdir($logDir, 0777, true);
        }

        $logFile = $logDir . '/error.log';
        $timestamp = date('Y-m-d H:i:s');
        $message = "[{$timestamp}] {$error['type']}: {$error['message']} in {$error['file']} on line {$error['line']}\n";
        
        if (isset($error['trace'])) {
            $message .= "Stack trace:\n{$error['trace']}\n";
        }
        
        $message .= "----------------------------------------\n";
        
        error_log($message, 3, $logFile);
    }

    /**
     * Send error response to client
     * 
     * @param array $error Error details
     * @return void
     */
    private static function sendErrorResponse($error) {
        if (headers_sent()) {
            return;
        }

        header('HTTP/1.1 500 Internal Server Error');
        header('Content-Type: application/json');

        $response = [
            'success' => false,
            'message' => 'An error occurred while processing your request'
        ];

        if (Config::get('app.debug', false)) {
            $response['error'] = [
                'type' => $error['type'],
                'message' => $error['message'],
                'file' => $error['file'],
                'line' => $error['line']
            ];

            if (isset($error['trace'])) {
                $response['error']['trace'] = $error['trace'];
            }
        }

        echo json_encode($response);
        exit;
    }
}

// Initialize error handling
ErrorHandler::init();
?> 