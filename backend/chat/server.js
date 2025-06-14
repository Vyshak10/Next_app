const WebSocket = require('ws');
const http = require('http');
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');

// Create HTTP server
const server = http.createServer();
const wss = new WebSocket.Server({ server });

// Database connection
const dbConfig = {
    host: 'localhost',
    user: 'your_username',
    password: 'your_password',
    database: 'next_app_db'
};

// Store connected clients
const clients = new Map();

// JWT secret
const JWT_SECRET = 'your_jwt_secret';

// Handle WebSocket connections
wss.on('connection', async (ws, req) => {
    try {
        // Get token from URL
        const url = new URL(req.url, 'ws://localhost');
        const token = url.searchParams.get('token');

        if (!token) {
            ws.close(1008, 'Authentication required');
            return;
        }

        // Verify token
        const decoded = jwt.verify(token, JWT_SECRET);
        const userId = decoded.userId;

        // Store client
        clients.set(userId, ws);

        // Send online status to other users
        broadcastUserStatus(userId, true);

        // Handle messages
        ws.on('message', async (message) => {
            try {
                const data = JSON.parse(message);
                
                switch (data.type) {
                    case 'message':
                        await handleMessage(userId, data);
                        break;
                    case 'typing':
                        handleTyping(userId, data);
                        break;
                    case 'read':
                        await handleReadReceipt(userId, data);
                        break;
                }
            } catch (error) {
                console.error('Error handling message:', error);
            }
        });

        // Handle disconnection
        ws.on('close', () => {
            clients.delete(userId);
            broadcastUserStatus(userId, false);
        });

    } catch (error) {
        console.error('Connection error:', error);
        ws.close(1011, 'Internal server error');
    }
});

// Handle new message
async function handleMessage(senderId, data) {
    const { recipientId, content, type } = data;
    
    try {
        const connection = await mysql.createConnection(dbConfig);
        
        // Store message in database
        const [result] = await connection.execute(
            'INSERT INTO messages (sender_id, recipient_id, content, type, created_at) VALUES (?, ?, ?, ?, NOW())',
            [senderId, recipientId, content, type]
        );
        
        const messageId = result.insertId;

        // Get message with sender info
        const [messages] = await connection.execute(
            `SELECT m.*, u.email as sender_email 
             FROM messages m 
             JOIN users u ON m.sender_id = u.id 
             WHERE m.id = ?`,
            [messageId]
        );

        const message = messages[0];

        // Send to recipient if online
        const recipientWs = clients.get(recipientId);
        if (recipientWs) {
            recipientWs.send(JSON.stringify({
                type: 'message',
                message: {
                    ...message,
                    status: 'delivered'
                }
            }));
        }

        // Send confirmation to sender
        const senderWs = clients.get(senderId);
        if (senderWs) {
            senderWs.send(JSON.stringify({
                type: 'message_sent',
                messageId,
                status: 'sent'
            }));
        }

        await connection.end();
    } catch (error) {
        console.error('Error handling message:', error);
    }
}

// Handle typing status
function handleTyping(userId, data) {
    const { recipientId, isTyping } = data;
    const recipientWs = clients.get(recipientId);
    
    if (recipientWs) {
        recipientWs.send(JSON.stringify({
            type: 'typing',
            userId,
            isTyping
        }));
    }
}

// Handle read receipts
async function handleReadReceipt(userId, data) {
    const { messageId } = data;
    
    try {
        const connection = await mysql.createConnection(dbConfig);
        
        // Update message status
        await connection.execute(
            'UPDATE messages SET status = "read" WHERE id = ? AND recipient_id = ?',
            [messageId, userId]
        );

        // Get message sender
        const [messages] = await connection.execute(
            'SELECT sender_id FROM messages WHERE id = ?',
            [messageId]
        );

        if (messages.length > 0) {
            const senderId = messages[0].sender_id;
            const senderWs = clients.get(senderId);
            
            if (senderWs) {
                senderWs.send(JSON.stringify({
                    type: 'read_receipt',
                    messageId,
                    readBy: userId
                }));
            }
        }

        await connection.end();
    } catch (error) {
        console.error('Error handling read receipt:', error);
    }
}

// Broadcast user status
function broadcastUserStatus(userId, isOnline) {
    const message = JSON.stringify({
        type: 'status',
        userId,
        isOnline
    });

    clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
}

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`WebSocket server is running on port ${PORT}`);
}); 