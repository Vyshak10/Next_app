<?php
require_once '../bootstrap.php';
require_once '../includes/WebSocketNotifier.php';

// Require authentication
$user = AuthMiddleware::requireAuth();

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (!isset($data['participants']) || !is_array($data['participants']) || empty($data['participants'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'At least one participant is required'
    ]);
    exit;
}

// Add current user to participants if not already included
if (!in_array($user['id'], $data['participants'])) {
    $data['participants'][] = $user['id'];
}

try {
    // Start transaction
    $db->beginTransaction();

    // Create conversation
    $stmt = $db->prepare("
        INSERT INTO conversations (title, type, created_at, updated_at)
        VALUES (?, ?, NOW(), NOW())
    ");
    
    // Set conversation title based on participants
    $title = '';
    if (count($data['participants']) === 2) {
        // For direct messages, get the other participant's name
        $otherUserId = array_filter($data['participants'], function($id) use ($user) {
            return $id != $user['id'];
        })[0];
        
        $stmt2 = $db->prepare("
            SELECT 
                CASE 
                    WHEN u.user_type = 'company' THEN cp.company_name
                    WHEN u.user_type = 'startup' THEN sp.startup_name
                    WHEN u.user_type = 'seeker' THEN sk.full_name
                END as name
            FROM users u
            LEFT JOIN company_profiles cp ON u.id = cp.user_id
            LEFT JOIN startup_profiles sp ON u.id = sp.user_id
            LEFT JOIN seeker_profiles sk ON u.id = sk.user_id
            WHERE u.id = ?
        ");
        $stmt2->execute([$otherUserId]);
        $result = $stmt2->fetch();
        $title = $result['name'];
    } else {
        // For group chats, use a default title
        $title = 'Group Chat';
    }
    
    $stmt->execute([$title, count($data['participants']) > 2 ? 'group' : 'direct']);
    $conversationId = $db->lastInsertId();

    // Add participants
    $stmt = $db->prepare("
        INSERT INTO conversation_participants (conversation_id, user_id, joined_at)
        VALUES (?, ?, NOW())
    ");
    
    foreach ($data['participants'] as $participantId) {
        $stmt->execute([$conversationId, $participantId]);
    }

    // Get conversation details with participants
    $stmt = $db->prepare("
        SELECT 
            c.id,
            c.title,
            c.type,
            c.created_at,
            c.updated_at,
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
            ) as participants
        FROM conversations c
        WHERE c.id = ?
    ");
    
    $stmt->execute([$conversationId]);
    $conversation = $stmt->fetch();

    // Format participants data
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

    // Commit transaction
    $db->commit();

    // Send WebSocket notifications to all participants
    foreach ($data['participants'] as $participantId) {
        if ($participantId !== $user['id']) {
            WebSocketNotifier::notifyNewMessage(
                $conversationId,
                [
                    'type' => 'conversation_created',
                    'conversation' => $conversation
                ],
                $user['id']
            );
        }
    }

    echo json_encode([
        'success' => true,
        'data' => [
            'conversation' => $conversation
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
        'message' => 'Failed to create conversation: ' . $e->getMessage()
    ]);
}
?> 