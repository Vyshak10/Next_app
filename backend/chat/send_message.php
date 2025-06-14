<?php
require_once '../bootstrap.php';
require_once '../includes/WebSocketNotifier.php';

// Require authentication
$user = AuthMiddleware::requireAuth();

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (!isset($data['conversation_id']) || !isset($data['content']) || !isset($data['type'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing required fields'
    ]);
    exit;
}

try {
    // Check if user is part of the conversation
    $stmt = $db->prepare("
        SELECT 1 
        FROM conversation_participants 
        WHERE conversation_id = ? AND user_id = ?
    ");
    $stmt->execute([$data['conversation_id'], $user['id']]);
    
    if (!$stmt->fetch()) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'You are not part of this conversation'
        ]);
        exit;
    }

    // Start transaction
    $db->beginTransaction();

    // Insert message
    $stmt = $db->prepare("
        INSERT INTO messages (conversation_id, sender_id, content, type, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ");
    $stmt->execute([
        $data['conversation_id'],
        $user['id'],
        $data['content'],
        $data['type']
    ]);
    
    $messageId = $db->lastInsertId();

    // Update conversation's updated_at timestamp
    $stmt = $db->prepare("
        UPDATE conversations 
        SET updated_at = NOW() 
        WHERE id = ?
    ");
    $stmt->execute([$data['conversation_id']]);

    // Get the inserted message with sender information
    $stmt = $db->prepare("
        SELECT 
            m.id,
            m.content,
            m.type,
            m.created_at,
            m.sender_id,
            CASE 
                WHEN u.user_type = 'company' THEN cp.company_name
                WHEN u.user_type = 'startup' THEN sp.startup_name
                WHEN u.user_type = 'seeker' THEN sk.full_name
            END as sender_name,
            u.user_type as sender_type
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        LEFT JOIN company_profiles cp ON u.id = cp.user_id
        LEFT JOIN startup_profiles sp ON u.id = sp.user_id
        LEFT JOIN seeker_profiles sk ON u.id = sk.user_id
        WHERE m.id = ?
    ");
    
    $stmt->execute([$messageId]);
    $message = $stmt->fetch();

    // Commit transaction
    $db->commit();

    // Send WebSocket notification
    WebSocketNotifier::notifyNewMessage(
        $data['conversation_id'],
        $message,
        $user['id']
    );

    echo json_encode([
        'success' => true,
        'data' => [
            'message' => $message
        ]
    ]);

} catch (Exception $e) {
    // Rollback transaction on error
    if ($db->inTransaction()) {
        $db->rollBack();
    }

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to send message: ' . $e->getMessage()
    ]);
}
?> 