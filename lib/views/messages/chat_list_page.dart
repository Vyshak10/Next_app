import 'package:flutter/material.dart';//chat_list_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import 'chat_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _chats = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadUnreadCount();
  }

  Future<String?> _getCurrentUserId() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'user_id');
  }

  Future<void> _loadChats() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    try {
      final response = await _apiService.get('get_chats.php?user_id=$userId');
      final chats = response['chats'] as List;
      setState(() {
        _chats = chats.map((chat) {
          return {
            'user': UserProfile.fromJson(chat['user']),
            'lastMessage': Message.fromJson(chat['last_message']),
            'conversationId': chat['conversation_id'],
            'unread': chat['unread'] ?? false,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chats: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    try {
      final response = await http.get(Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_unread_count.php?user_id=$userId'));
      final data = jsonDecode(response.body);
      setState(() {
        _unreadCount = data['unread_count'] ?? 0;
      });
    } catch (e) {
      // ignore error
    }
  }

  Future<void> _showUserListAndStartChat() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    final response = await http.get(Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_users.php?user_id=$userId'));
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
                // Fetch or create conversationId from backend
                final convResponse = await http.post(
                  Uri.parse('https://indianrupeeservices.in/NEXT/backend/create_conversation.php'),
                  body: {
                    'user1_id': userId,
                    'user2_id': user['id'].toString(),
                  },
                );
                final convData = jsonDecode(convResponse.body);
                final conversationId = convData['conversation_id'].toString();
                // Navigate to chat page with selected user and conversationId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      otherUser: UserProfile(
                        id: user['id'].toString(),
                        userId: user['id'].toString(),
                        userType: user['user_type'] ?? '',
                        name: user['name'],
                        skills: [],
                        avatarUrl: user['avatar_url'],
                        description: user['description'],
                        notifyEnabled: user['notify_enabled'] ?? true,
                      ),
                      conversationId: conversationId,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    await http.post(
      Uri.parse('https://indianrupeeservices.in/NEXT/backend/delete_conversation.php'),
      body: {'conversation_id': conversationId},
    );
    _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.mark_chat_unread),
                onPressed: _loadUnreadCount,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: _chats.isEmpty
            ? const Center(
                child: Text('No messages yet'),
              )
            : ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  final user = chat['user'] as UserProfile;
                  final lastMessage = chat['lastMessage'] as Message;
                  final conversationId = chat['conversationId'];
                  final unread = chat['unread'] ?? false;
                  return Dismissible(
                    key: ValueKey(conversationId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteConversation(conversationId),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.avatarUrl != null
                            ? CachedNetworkImageProvider(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(user.name[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.name),
                      subtitle: Text(
                        lastMessage.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: unread
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              otherUser: user,
                              conversationId: conversationId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 16),
          child: FloatingActionButton(
            onPressed: _showUserListAndStartChat,
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.person_add_alt_1),
            tooltip: 'Start New Conversation',
            elevation: 2,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
    );
  }
} 