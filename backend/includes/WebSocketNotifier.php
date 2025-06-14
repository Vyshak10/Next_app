<?php
class WebSocketNotifier {
    private static $wsServerUrl;
    private static $jwtSecret;

    public static function init($wsServerUrl, $jwtSecret) {
        self::$wsServerUrl = $wsServerUrl;
        self::$jwtSecret = $jwtSecret;
    }

    public static function notifyNewMessage($conversationId, $message, $senderId) {
        $data = [
            'type' => 'message',
            'conversationId' => $conversationId,
            'message' => $message,
            'senderId' => $senderId
        ];
        self::sendToWebSocket($data);
    }

    public static function notifyMessageRead($conversationId, $messageId, $userId) {
        $data = [
            'type' => 'read',
            'conversationId' => $conversationId,
            'messageId' => $messageId,
            'userId' => $userId
        ];
        self::sendToWebSocket($data);
    }

    public static function notifyTypingStatus($conversationId, $userId, $isTyping) {
        $data = [
            'type' => 'typing',
            'conversationId' => $conversationId,
            'userId' => $userId,
            'isTyping' => $isTyping
        ];
        self::sendToWebSocket($data);
    }

    public static function notifyUserStatus($userId, $status) {
        $data = [
            'type' => 'status',
            'userId' => $userId,
            'status' => $status
        ];
        self::sendToWebSocket($data);
    }

    private static function sendToWebSocket($data) {
        if (!self::$wsServerUrl) {
            error_log('WebSocket server URL not configured');
            return;
        }

        $ch = curl_init(self::$wsServerUrl);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Authorization: Bearer ' . self::generateToken()
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        
        if ($httpCode !== 200) {
            error_log('Failed to send WebSocket notification: ' . $response);
        }
        
        curl_close($ch);
    }

    private static function generateToken() {
        if (!self::$jwtSecret) {
            error_log('JWT secret not configured');
            return '';
        }

        $payload = [
            'iat' => time(),
            'exp' => time() + 60, // Token expires in 1 minute
            'type' => 'notification'
        ];

        return jwt_encode($payload, self::$jwtSecret, 'HS256');
    }
}
?> 