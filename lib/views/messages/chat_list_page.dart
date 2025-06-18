import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _chats = []; // List of {user: UserProfile, lastMessage: Message}

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      // TODO: Implement get_chats.php endpoint
      // For now, we'll use a mock implementation
      final response = await _apiService.get('get_chats.php');
      final chats = response['chats'] as List;
      
      setState(() {
        _chats = chats.map((chat) {
          return {
            'user': UserProfile.fromJson(chat['user']),
            'lastMessage': Message.fromJson(chat['last_message']),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
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

                  return ListTile(
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
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeago.format(lastMessage.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (!lastMessage.isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            otherUser: user,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
} 