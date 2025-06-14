const WebSocket = require('ws');
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Create WebSocket server
const wss = new WebSocket.Server({ port: process.env.WS_PORT || 8080 });

// Store connected clients
const clients = new Map();

// Database connection pool
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'next_app_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// JWT secret
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Handle WebSocket connections
wss.on('connection', async (ws, req) => {
    console.log('New client connected');

    // Handle authentication
    const token = req.url.split('token=')[1];
    if (!token) {
        ws.close(1008, 'Authentication required');
        return;
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        const userId = decoded.userId;

        // Store client connection
        clients.set(userId, ws);

        // Send online status to user's contacts
        await broadcastUserStatus(userId, 'online');

        // Handle messages
        ws.on('message', async (message) => {
            try {
                const data = JSON.parse(message);
                handleMessage(userId, data);
            } catch (error) {
                console.error('Error handling message:', error);
                ws.send(JSON.stringify({
                    type: 'error',
                    message: 'Invalid message format'
                }));
            }
        });

        // Handle disconnection
        ws.on('close', async () => {
            clients.delete(userId);
            await broadcastUserStatus(userId, 'offline');
            console.log(`Client ${userId} disconnected`);
        });

    } catch (error) {
        console.error('Authentication error:', error);
        ws.close(1008, 'Invalid token');
    }
});

// Handle different types of messages
async function handleMessage(userId, data) {
    switch (data.type) {
        case 'message':
            await handleNewMessage(userId, data);
            break;
        case 'typing':
            await handleTypingStatus(userId, data);
            break;
        case 'read':
            await handleMessageRead(userId, data);
            break;
        default:
            console.warn('Unknown message type:', data.type);
    }
}

// Handle new message
async function handleNewMessage(userId, data) {
    try {
        // Get conversation participants
        const [participants] = await pool.execute(
            'SELECT user_id FROM conversation_participants WHERE conversation_id = ?',
            [data.conversationId]
        );

        // Broadcast message to all participants
        for (const participant of participants) {
            const client = clients.get(participant.user_id);
            if (client && participant.user_id !== userId) {
                client.send(JSON.stringify({
                    type: 'message',
                    data: {
                        conversationId: data.conversationId,
                        message: data.message
                    }
                }));
            }
        }
    } catch (error) {
        console.error('Error handling new message:', error);
    }
}

// Handle typing status
async function handleTypingStatus(userId, data) {
    try {
        // Get conversation participants
        const [participants] = await pool.execute(
            'SELECT user_id FROM conversation_participants WHERE conversation_id = ?',
            [data.conversationId]
        );

        // Broadcast typing status to other participants
        for (const participant of participants) {
            const client = clients.get(participant.user_id);
            if (client && participant.user_id !== userId) {
                client.send(JSON.stringify({
                    type: 'typing',
                    data: {
                        conversationId: data.conversationId,
                        userId: userId,
                        isTyping: data.isTyping
                    }
                }));
            }
        }
    } catch (error) {
        console.error('Error handling typing status:', error);
    }
}

// Handle message read status
async function handleMessageRead(userId, data) {
    try {
        // Get conversation participants
        const [participants] = await pool.execute(
            'SELECT user_id FROM conversation_participants WHERE conversation_id = ?',
            [data.conversationId]
        );

        // Broadcast read status to other participants
        for (const participant of participants) {
            const client = clients.get(participant.user_id);
            if (client && participant.user_id !== userId) {
                client.send(JSON.stringify({
                    type: 'read',
                    data: {
                        conversationId: data.conversationId,
                        userId: userId,
                        messageId: data.messageId
                    }
                }));
            }
        }
    } catch (error) {
        console.error('Error handling message read status:', error);
    }
}

// Broadcast user online/offline status
async function broadcastUserStatus(userId, status) {
    try {
        // Get user's conversations
        const [conversations] = await pool.execute(
            'SELECT DISTINCT conversation_id FROM conversation_participants WHERE user_id = ?',
            [userId]
        );

        // For each conversation, get participants and notify them
        for (const conversation of conversations) {
            const [participants] = await pool.execute(
                'SELECT user_id FROM conversation_participants WHERE conversation_id = ?',
                [conversation.conversation_id]
            );

            for (const participant of participants) {
                const client = clients.get(participant.user_id);
                if (client && participant.user_id !== userId) {
                    client.send(JSON.stringify({
                        type: 'status',
                        data: {
                            userId: userId,
                            status: status
                        }
                    }));
                }
            }
        }
    } catch (error) {
        console.error('Error broadcasting user status:', error);
    }
}

// Start server
console.log(`WebSocket server is running on port ${process.env.WS_PORT || 8080}`); 