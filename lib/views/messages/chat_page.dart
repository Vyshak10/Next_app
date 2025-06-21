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
    print('ChatPage opened for conversationId: \'${widget.conversationId}\' with otherUser: \'${widget.otherUser.userId}\'');
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final storage = FlutterSecureStorage();
    final id = await storage.read(key: 'user_id');
    setState(() {
      _currentUserId = id;
    });
    print('Current user ID in ChatPage: \'$_currentUserId\'');
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
    if (_currentUserId == null) return;
    try {
      final response = await http.get(Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_messages.php?conversation_id=${widget.conversationId}'));
      final data = jsonDecode(response.body);
      final messages = data['messages'] as List;
      print('Loaded messages from backend:');
      print(messages);
      setState(() {
        _messages = messages.map((json) => Message.fromJson(json)).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
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
    if (message.isEmpty || _isSending || _currentUserId == null || widget.conversationId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/send_message.php'),
        body: {
          'conversation_id': widget.conversationId!,
          'senders_id': _currentUserId!,
          'receivers_id': widget.otherUser.userId,
          'content': message,
        },
      );

      if (response.statusCode == 200) {
        _messageController.clear();
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == _currentUserId;
                return Dismissible(
                  key: ValueKey(message.id),
                  direction: isMe ? DismissDirection.endToStart : DismissDirection.none,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteMessage(message.id),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            message.content,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(message.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  onPressed: _sendMessage,
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