<?php
require_once '../bootstrap.php';
require_once '../includes/WebSocketNotifier.php';

// Require authentication
$user = AuthMiddleware::requireAuth();

// Get conversation ID from query parameter
$conversationId = $_GET['conversation_id'] ?? null;

if (!$conversationId) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Conversation ID is required'
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
    $stmt->execute([$conversationId, $user['id']]);
    
    if (!$stmt->fetch()) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'You are not part of this conversation'
        ]);
        exit;
    }

    // Get messages with sender information
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
            u.user_type as sender_type,
            (
                SELECT COUNT(*) 
                FROM message_reads 
                WHERE message_id = m.id
            ) as read_count
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        LEFT JOIN company_profiles cp ON u.id = cp.user_id
        LEFT JOIN startup_profiles sp ON u.id = sp.user_id
        LEFT JOIN seeker_profiles sk ON u.id = sk.user_id
        WHERE m.conversation_id = ?
        ORDER BY m.created_at ASC
    ");
    
    $stmt->execute([$conversationId]);
    $messages = $stmt->fetchAll();

    // Get unread messages
    $stmt = $db->prepare("
        SELECT m.id
        FROM messages m
        LEFT JOIN message_reads mr ON m.id = mr.message_id AND mr.user_id = ?
        WHERE m.conversation_id = ?
        AND m.sender_id != ?
        AND mr.id IS NULL
    ");
    $stmt->execute([$user['id'], $conversationId, $user['id']]);
    $unreadMessages = $stmt->fetchAll(PDO::FETCH_COLUMN);

    if (!empty($unreadMessages)) {
        // Start transaction
        $db->beginTransaction();

        // Mark messages as read
        $stmt = $db->prepare("
            INSERT INTO message_reads (message_id, user_id, read_at)
            VALUES (?, ?, NOW())
        ");
        
        foreach ($unreadMessages as $messageId) {
            $stmt->execute([$messageId, $user['id']]);
            
            // Send WebSocket notification for each read message
            WebSocketNotifier::notifyMessageRead(
                $conversationId,
                $messageId,
                $user['id']
            );
        }

        // Update last read timestamp
        $stmt = $db->prepare("
            UPDATE conversation_participants 
            SET last_read_at = NOW() 
            WHERE conversation_id = ? AND user_id = ?
        ");
        $stmt->execute([$conversationId, $user['id']]);

        // Commit transaction
        $db->commit();
    }

    echo json_encode([
        'success' => true,
        'data' => [
            'messages' => $messages
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
        'message' => 'Failed to fetch messages: ' . $e->getMessage()
    ]);
}
?> 