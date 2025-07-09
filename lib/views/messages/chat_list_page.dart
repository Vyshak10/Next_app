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
  bool _showSearch = false;
  String _searchQuery = '';
  String _filter = 'All';

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
            'user': UserProfile(
              id: chat['user']['id'].toString(),
              userId: chat['user']['user_id'].toString(),
              userType: chat['user']['user_type']?.toString() ?? '',
              name: chat['user']['name']?.toString() ?? '',
              skills: chat['user']['skills'] is List ? List<String>.from(chat['user']['skills']) : [],
              avatarUrl: chat['user']['avatar_url']?.toString(),
              description: chat['user']['description']?.toString(),
              notifyEnabled: chat['user']['notify_enabled'] is bool ? chat['user']['notify_enabled'] : true,
            ),
            'lastMessage': Message.fromJson(chat['last_message']),
            'conversationId': chat['conversation_id'].toString(),
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

  List<Map<String, dynamic>> get _filteredChats {
    return _chats.where((chat) {
      final user = chat['user'] as UserProfile;
      final matchesQuery = _searchQuery.isEmpty || user.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _filter == 'All' || user.userType.toLowerCase() == _filter.toLowerCase();
      return matchesQuery && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: null,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search, color: Colors.blueAccent),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.blueAccent),
            tooltip: 'Start New Chat',
            onPressed: _showUserListAndStartChat,
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _filter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Company', child: Text('Company')),
                      DropdownMenuItem(value: 'Startup', child: Text('Startup')),
                    ],
                    onChanged: (v) => setState(() => _filter = v!),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadChats,
              child: _filteredChats.isEmpty
                  ? const Center(child: Text('No messages yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      itemCount: _filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = _filteredChats[index];
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
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: unread ? 4 : 1,
                            color: unread ? Colors.blue.shade50 : Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: user.avatarUrl != null
                                    ? CachedNetworkImageProvider(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(user.name[0].toUpperCase())
                                    : null,
                              ),
                              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: lastMessage.content.isNotEmpty
                                  ? Text(lastMessage.content, maxLines: 1, overflow: TextOverflow.ellipsis)
                                  : const Text('No messages yet', style: TextStyle(color: Colors.grey)),
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
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
} 