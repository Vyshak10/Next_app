//messages.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

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

// Main Messages Page
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with SingleTickerProviderStateMixin {
  int _unreadCount = 0;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeController.forward();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_unread_count.php?user_id=$userId'),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _unreadCount = data['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<String?> _getCurrentUserId() async {
    return '6852'; // Demo User ID
  }

  void _showUsersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const UsersTab(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          _buildNotificationBadge(),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.withOpacity(0.1),
            height: 1,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            ChatListTab(onUnreadCountChanged: (count) {
              if (mounted) {
                setState(() {
                  _unreadCount = count;
                });
              }
            }),
            _buildFAB(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    if (_unreadCount == 0) return const SizedBox.shrink();
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$_unreadCount New',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: FloatingActionButton.extended(
              heroTag: 'users_fab',
              backgroundColor: Colors.blueAccent,
              onPressed: _showUsersModal,
              icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
              label: const Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              elevation: 4,
            ),
          );
        },
      ),
    );
  }
}

// Chat List Tab
class ChatListTab extends StatefulWidget {
  final Function(int) onUnreadCountChanged;

  const ChatListTab({super.key, required this.onUnreadCountChanged});

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
    return '6852';
  }

  Future<void> _loadChats() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('http://indianrupeeservices.in/NEXT/backend/get_chats.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chats = data['chats'] as List;
        
        if (mounted) {
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

          final unreadCount = _chats.where((chat) => chat['unread'] == true).length;
          widget.onUnreadCountChanged(unreadCount);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: Colors.blueAccent,
      child: _chats.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return _buildChatCard(chat, index);
              },
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: ListTile(
            leading: const CircleAvatar(radius: 28, backgroundColor: Colors.white),
            title: Container(height: 12, width: 100, color: Colors.white),
            subtitle: Container(height: 10, width: 200, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_outlined, size: 64, color: Colors.blueAccent.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your inbox is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with startups and mentors!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, int index) {
    final user = chat['user'] as UserProfile;
    final lastMessage = chat['lastMessage'] as Message?;
    final unread = chat['unread'] ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      otherUser: user,
                      conversationId: chat['conversationId'].toString(),
                    ),
                  ),
                );
                if (result == true) _loadChats();
              },
              leading: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: unread 
                          ? const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue])
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                      child: user.avatarUrl == null
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))
                          : null,
                    ),
                  ),
                  if (unread)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (lastMessage != null)
                    Text(
                      timeago.format(lastMessage.createdAt, locale: 'en_short'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  lastMessage?.content ?? "Started a conversation",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread ? const Color(0xFF1E293B) : Colors.grey[500],
                    fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Users Tab (Discovery)
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

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

  Future<void> _loadUsers() async {
    try {
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_users.php?user_id=6852'),
      );
      if (response.statusCode == 200) {
        final usersList = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _users = usersList.map((user) => UserProfile.fromJson(user)).toList();
            _filteredUsers = _users;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHandle(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Connection',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              _buildSearchBar(),
            ],
          ),
        ),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent)) : _buildUserList(),
        ),
      ],
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 5,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search people or startups...',
          prefixIcon: Icon(Icons.search_rounded, color: Colors.blueAccent),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) return _buildEmptySearch();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user, index);
      },
    );
  }

  Widget _buildUserCard(UserProfile user, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, child) => Opacity(opacity: value, child: Transform.scale(scale: 0.95 + (0.05 * value), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: ListTile(
          onTap: () => _startChat(user),
          leading: CircleAvatar(
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
            child: user.avatarUrl == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.blueAccent)) : null,
          ),
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(user.userType, style: TextStyle(color: Colors.blueAccent.withOpacity(0.7), fontSize: 13)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Future<void> _startChat(UserProfile user) async {
    try {
      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/create_conversation.php'),
        body: {'user1_id': '6852', 'user2_id': user.id},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(otherUser: user, conversationId: data['conversation_id'].toString())));
        }
      }
    } catch (e) {}
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No matches found', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// Individual Chat Page
class ChatPage extends StatefulWidget {
  final UserProfile otherUser;
  final String conversationId;

  const ChatPage({
    super.key,
    required this.otherUser,
    required this.conversationId,
  });

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
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    const storage = FlutterSecureStorage();
    final id = await storage.read(key: 'user_id') ?? '6852';
    if (mounted) {
      setState(() {
        _currentUserId = id;
      });
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
    } catch (e) {}
  }

  Future<void> _loadMessages() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // For demo purposes, we will fetch or use empty list. 
      // Replace with your real API call if available.
      if (mounted) {
        setState(() {
          _messages = []; // Mock: start with empty list
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    
    setState(() => _isSending = true);
    
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId ?? '6852',
      receiverId: widget.otherUser.id,
      content: text,
      createdAt: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context, true),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            backgroundImage: widget.otherUser.avatarUrl != null ? CachedNetworkImageProvider(widget.otherUser.avatarUrl!) : null,
            child: widget.otherUser.avatarUrl == null ? Text(widget.otherUser.name.isNotEmpty ? widget.otherUser.name[0].toUpperCase() : '?') : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUser.name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                Text(widget.otherUser.userType, style: TextStyle(color: Colors.blueAccent.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.blueAccent), onPressed: () {}),
        IconButton(icon: const Icon(Icons.info_outline_rounded, color: Colors.grey), onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No messages yet', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId == _currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1E293B), fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(message.createdAt, locale: 'en_short'),
              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[400], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12, 
        bottom: MediaQuery.of(context).padding.bottom + 12
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.add, color: Color(0xFF64748B)), onPressed: () {}),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _messageController,
                maxLines: 4, minLines: 1,
                decoration: const InputDecoration(hintText: 'Type message...', border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              child: _isSending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
