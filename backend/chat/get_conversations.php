<?php
require_once '../bootstrap.php';

// Require authentication
$user = AuthMiddleware::requireAuth();

try {
    // Get user's conversations with latest message
    $stmt = $db->prepare("
        SELECT 
            c.id,
            c.title,
            c.type,
            c.updated_at,
            m.content as last_message,
            m.created_at as last_message_time,
            m.sender_id as last_message_sender,
            (
                SELECT COUNT(*) 
                FROM messages 
                WHERE conversation_id = c.id 
                AND created_at > COALESCE(cp.last_read_at, '1970-01-01')
            ) as unread_count,
            (
                SELECT GROUP_CONCAT(
                    CONCAT(
                        u.id, ':', 
                        CASE 
                            WHEN u.user_type = 'company' THEN cp.company_name
                            WHEN u.user_type = 'startup' THEN sp.startup_name
                            WHEN u.user_type = 'seeker' THEN sk.full_name
                        END
                    )
                )
                FROM conversation_participants cp2
                JOIN users u ON cp2.user_id = u.id
                LEFT JOIN company_profiles cp ON u.id = cp.user_id
                LEFT JOIN startup_profiles sp ON u.id = sp.user_id
                LEFT JOIN seeker_profiles sk ON u.id = sk.user_id
                WHERE cp2.conversation_id = c.id
                AND cp2.user_id != ?
            ) as participants
        FROM conversations c
        JOIN conversation_participants cp ON c.id = cp.conversation_id
        LEFT JOIN messages m ON m.id = (
            SELECT id 
            FROM messages 
            WHERE conversation_id = c.id 
            ORDER BY created_at DESC 
            LIMIT 1
        )
        WHERE cp.user_id = ?
        ORDER BY c.updated_at DESC
    ");
    
    $stmt->execute([$user['id'], $user['id']]);
    $conversations = $stmt->fetchAll();

    // Format participants data
    foreach ($conversations as &$conversation) {
        if ($conversation['participants']) {
            $participants = [];
            $parts = explode(',', $conversation['participants']);
            foreach ($parts as $part) {
                list($id, $name) = explode(':', $part);
                $participants[] = [
                    'id' => $id,
                    'name' => $name
                ];
            }
            $conversation['participants'] = $participants;
        } else {
            $conversation['participants'] = [];
        }
    }

    echo json_encode([
        'success' => true,
        'data' => [
            'conversations' => $conversations
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to fetch conversations: ' . $e->getMessage()
    ]);
}
?> 