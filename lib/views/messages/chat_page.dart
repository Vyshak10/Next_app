import 'package:flutter/material.dart';//chat_page.dart
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatPage extends StatefulWidget {
  final UserProfile otherUser;
  final String conversationId;

  const ChatPage({
    Key? key,
    required this.otherUser,
    required this.conversationId,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _apiService = ApiService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = true;
  List<Message> _messages = [];
  bool _isSending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    setState(() => _isLoading = false); // Force spinner off for demo
    print('ChatPage opened for conversationId: \'${widget.conversationId}\' with otherUser: \'${widget.otherUser.userId}\'');
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    // Hardcode user ID for demo/testing
    final id = '6852';
    setState(() {
      _currentUserId = id;
    });
    print('Current user ID in ChatPage: ' + _currentUserId!);
    _loadMessages();
    _markMessagesRead();
  }

  Future<void> _markMessagesRead() async {
    if (widget.conversationId == null || _currentUserId == null) return;
    await http.post(
      Uri.parse('https://indianrupeeservices.in/NEXT/backend/mark_message_read.php'),
      body: {
        'conversation_id': widget.conversationId!,
        'user_id': _currentUserId!,
      },
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    await http.post(
      Uri.parse('https://indianrupeeservices.in/NEXT/backend/delete_message.php'),
      body: {'message_id': messageId},
    );
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      // Simulate backend call or use empty list for demo
      setState(() {
        _messages = [];
      });
    } catch (e) {
      setState(() {
        _messages = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
    });
    // For demo: just add the message locally
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId ?? '6852',
      receiverId: widget.otherUser.userId,
      content: message,
      createdAt: DateTime.now(),
      isRead: true,
    );
    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
      _isSending = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // _isLoading = false; // Optionally force off here too
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUser.avatarUrl != null
                  ? NetworkImage(widget.otherUser.avatarUrl!)
                  : null,
              child: widget.otherUser.avatarUrl == null
                  ? Text(widget.otherUser.name[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUser.name),
                Text(
                  widget.otherUser.userType,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: _showUserListAndStartChat,
            tooltip: 'New Message',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet. Start chatting!'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _currentUserId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: widget.otherUser.avatarUrl != null
                                    ? NetworkImage(widget.otherUser.avatarUrl!)
                                    : null,
                                child: widget.otherUser.avatarUrl == null
                                    ? Text(
                                        widget.otherUser.name.isNotEmpty
                                            ? widget.otherUser.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                                      )
                                    : null,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFFFF9800) : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 18),
                                  ),
                                  border: isMe
                                      ? null
                                      : Border.all(color: const Color(0xFFFF9800), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : const Color(0xFF222222),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeago.format(message.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMe
                                            ? Colors.white.withOpacity(0.8)
                                            : const Color(0xFFFF9800).withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFFFF9800),
                                child: Icon(Icons.person, color: Colors.white, size: 18),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.12),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFFF9800), width: 1.2),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showUserListAndStartChat() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    final response = await http.get(
      Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_users.php?user_id=$userId'),
    );
    final users = jsonDecode(response.body) as List;
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Start New Chat'),
          children: users.map((user) {
            return SimpleDialogOption(
              child: Text(user['name']),
              onPressed: () async {
                Navigator.pop(context);
                // Get or create conversation
                final conversationId = await getOrCreateConversationId(userId, user['id'].toString());
                if (conversationId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        otherUser: UserProfile(
                          id: user['id'].toString(),
                          userId: user['id'].toString(),
                          userType: user['user_type'] ?? '',
                          name: user['name'] ?? '',
                          skills: user['skills'] != null ? List<String>.from(user['skills']) : [],
                          avatarUrl: user['avatar_url'],
                          description: user['description'],
                          notifyEnabled: user['notify_enabled'] ?? true,
                        ),
                        conversationId: conversationId,
                      ),
                    ),
                  );
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<String?> _getCurrentUserId() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'user_id');
  }
}

Future<String?> getOrCreateConversationId(String user1Id, String user2Id) async {
  final response = await http.post(
    Uri.parse('https://indianrupeeservices.in/NEXT/backend/create_conversation.php'),
    body: {
      'user1_id': user1Id,
      'user2_id': user2Id,
    },
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['conversation_id']?.toString();
  }
  return null;
} 