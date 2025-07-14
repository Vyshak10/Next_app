//messages.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Models
class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      senderId: json['sender_id'].toString(),
      receiverId: json['receiver_id'].toString(),
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }
}

class UserProfile {
  final String id;
  final String userId;
  final String userType;
  final String name;
  final List<String> skills;
  final String? avatarUrl;
  final String? description;
  final bool notifyEnabled;

  UserProfile({
    required this.id,
    required this.userId,
    required this.userType,
    required this.name,
    required this.skills,
    this.avatarUrl,
    this.description,
    this.notifyEnabled = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? json['id'].toString(),
      userType: json['user_type'] ?? '',
      name: json['name'] ?? '',
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      avatarUrl: json['avatar_url'],
      description: json['description'],
      notifyEnabled: json['notify_enabled'] == 1 || json['notify_enabled'] == true,
    );
  }
}

// Main Messages Page with TabBar
class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with SingleTickerProviderStateMixin {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_unread_count.php?user_id=$userId'),
      );
      final data = jsonDecode(response.body);
      setState(() {
        _unreadCount = data['unread_count'] ?? 0;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<String?> _getCurrentUserId() async {
    // TEMP: Hardcode user ID for demo
    return '6852';
  }

  void _showUsersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: UsersTab(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Messages'),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
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
      body: Stack(
        children: [
          ChatListTab(onUnreadCountChanged: (count) {
            setState(() {
              _unreadCount = count;
            });
          }),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'users_fab',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _showUsersModal,
              child: const Icon(Icons.people, color: Colors.blueAccent),
              tooltip: 'Browse Users',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Chat List Tab
class ChatListTab extends StatefulWidget {
  final Function(int) onUnreadCountChanged;

  const ChatListTab({Key? key, required this.onUnreadCountChanged}) : super(key: key);

  @override
  _ChatListTabState createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<String?> _getCurrentUserId() async {
    // TEMP: Hardcode user ID for demo
    return '6852';
  }

  Future<void> _loadChats() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('http://indianrupeeservices.in/NEXT/backend/get_chats.php?user_id=$userId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chats = data['chats'] as List;
        
        setState(() {
          _chats = chats.map((chat) {
            final lastMessage = chat['last_message'];
            return {
              'user': UserProfile.fromJson(chat['user']),
              'lastMessage': (lastMessage is Map && lastMessage.isNotEmpty)
                  ? Message.fromJson(Map<String, dynamic>.from(lastMessage))
                  : null,
              'conversationId': chat['conversation_id'],
              'unread': chat['unread'] ?? false,
            };
          }).toList();
          _isLoading = false;
        });

        // Update unread count
        final unreadCount = _chats.where((chat) => chat['unread'] == true).length;
        widget.onUnreadCountChanged(unreadCount);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chats: $e')),
        );
      }
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await http.post(
        Uri.parse('http://indianrupeeservices.in/NEXT/backend/delete_conversation.php'),
        body: {'conversation_id': conversationId},
      );
      _loadChats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting conversation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: _chats.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a new chat from the Users tab',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                final user = chat['user'] as UserProfile;
                final lastMessage = chat['lastMessage'] as Message?;
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
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Conversation'),
                          content: Text('Are you sure you want to delete this conversation with ${user.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (_) => _deleteConversation(conversationId),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: unread ? const Color(0xFFFF9800) : Colors.grey[200]!, width: 1.2),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: user.avatarUrl != null
                            ? CachedNetworkImageProvider(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                              )
                            : null,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF9800),
                      ),
                      title: Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                          color: unread ? const Color(0xFFFF9800) : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lastMessage != null) ...[
                            Text(
                              lastMessage.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              timeago.format(lastMessage.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ] else ...[
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: unread
                          ? Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9800),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '●',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              otherUser: user,
                              conversationId: conversationId.toString(),
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadChats(); // Refresh chat list when returning from chat
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Users Tab
class UsersTab extends StatefulWidget {
  const UsersTab({Key? key}) : super(key: key);

  @override
  _UsersTabState createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  bool _isLoading = true;
  List<UserProfile> _users = [];
  List<UserProfile> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<String?> _getCurrentUserId() async {
    // TEMP: Hardcode user ID for demo
    return '6852';
  }

  Future<void> _loadUsers() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_users.php?user_id=6852'),
      );

      if (response.statusCode == 200) {
        print('get_users.php response: \\n${response.body}');
        final usersList = jsonDecode(response.body) as List;
        print('Parsed users list: $usersList');
        setState(() {
          _users = usersList.map((user) => UserProfile.fromJson(user)).toList();
          _filteredUsers = _users;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(query) ||
               user.userType.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _startChatWithUser(UserProfile user) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/create_conversation.php'),
        body: {
          'user1_id': userId,
          'user2_id': user.id,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversationId = data['conversation_id'].toString();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                otherUser: user,
                conversationId: conversationId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No users found'
                              : 'No users available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFFF9800), width: 1.2),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: user.avatarUrl != null
                                ? CachedNetworkImageProvider(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                                  )
                                : null,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF9800),
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.userType,
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (user.description != null && user.description!.isNotEmpty)
                                Text(
                                  user.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF9800)),
                            onPressed: () => _startChatWithUser(user),
                            tooltip: 'Start Chat',
                          ),
                          onTap: () => _startChatWithUser(user),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Individual Chat Page
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
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    const storage = FlutterSecureStorage();
    final id = await storage.read(key: 'user_id');
    setState(() {
      _currentUserId = id;
    });
    if (id != null) {
      _loadMessages();
      _markMessagesRead();
    }
  }

  Future<void> _markMessagesRead() async {
    if (_currentUserId == null) return;
    try {
      await http.post(
        Uri.parse('http://indianrupeeservices.in/NEXT/backend/mark_message_read.php'),
        body: {
          'conversation_id': widget.conversationId,
          'user_id': _currentUserId!,
        },
      );
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await http.post(
        Uri.parse('http://indianrupeeservices.in/NEXT/backend/delete_message.php'),
        body: {'message_id': messageId},
      );
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting message: $e')),
        );
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUser.avatarUrl != null
                  ? CachedNetworkImageProvider(widget.otherUser.avatarUrl!)
                  : null,
              child: widget.otherUser.avatarUrl == null
                  ? Text(
                      widget.otherUser.name.isNotEmpty
                          ? widget.otherUser.name[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.otherUser.userType,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                      return Dismissible(
                        key: ValueKey(message.id),
                        direction: isMe ? DismissDirection.endToStart : DismissDirection.none,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: isMe ? (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Message'),
                                content: const Text('Are you sure you want to delete this message?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                        } : null,
                        onDismissed: (_) => _deleteMessage(message.id),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: widget.otherUser.avatarUrl != null
                                      ? CachedNetworkImageProvider(widget.otherUser.avatarUrl!)
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
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
}