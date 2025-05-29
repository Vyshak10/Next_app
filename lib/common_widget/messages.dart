import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  final String userId;
  const MessagesScreen({super.key, required this.userId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;
  final TextEditingController messageController = TextEditingController();
  String? selectedConversationId;
  List<Map<String, dynamic>> messages = [];
  late RealtimeChannel messageChannel;
  bool showConversationList = true;

  @override
  void initState() {
    super.initState();
    fetchConversations();
    subscribeToMessages();
  }

  @override
  void dispose() {
    messageController.dispose();
    messageChannel.unsubscribe();
    super.dispose();
  }

  Future<void> fetchConversations() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('conversations')
          .select('*, participants:conversation_participants(user_id, profiles:profiles(id, full_name, avatar_url))')
          .contains('participants', [{'user_id': widget.userId}])
          .order('updated_at', ascending: false);

      setState(() {
        conversations = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    try {
      final response = await supabase
          .from('messages')
          .select('*, sender:profiles(full_name, avatar_url)')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      setState(() {
        messages = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  void subscribeToMessages() {
    messageChannel = supabase.channel('public:messages');

    messageChannel
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newMessage = payload.newRecord;
        if (newMessage != null && newMessage['conversation_id'] == selectedConversationId) {
          fetchMessages(selectedConversationId!);
        }
      },
    ).subscribe();
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty || selectedConversationId == null) return;

    try {
      await supabase.from('messages').insert({
        'conversation_id': selectedConversationId,
        'sender_id': widget.userId,
        'content': messageController.text.trim(),
      });

      messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> createNewConversation(String otherUserId) async {
    try {
      final response = await supabase.from('conversations').insert({
        'participants': [
          {'user_id': widget.userId},
          {'user_id': otherUserId}
        ]
      }).select().single();

      setState(() {
        selectedConversationId = response['id'];
        showConversationList = false;
      });
      fetchConversations();
      fetchMessages(response['id']);
    } catch (e) {
      print('Error creating conversation: $e');
    }
  }

  Widget _buildConversationList() {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final otherParticipant = (conversation['participants'] as List)
            .firstWhere((p) => p['user_id'] != widget.userId);
        final profile = otherParticipant['profiles'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profile['avatar_url'] != null
                ? NetworkImage(profile['avatar_url'])
                : null,
            child: profile['avatar_url'] == null
                ? Text(profile['full_name'][0].toUpperCase())
                : null,
          ),
          title: Text(
            profile['full_name'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            conversation['last_message'] ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(conversation['updated_at']),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (conversation['unread_count'] > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    conversation['unread_count'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            setState(() {
              selectedConversationId = conversation['id'];
              showConversationList = false;
            });
            fetchMessages(conversation['id']);
          },
        );
      },
    );
  }

  Widget _buildChatScreen() {
    final conversation = conversations.firstWhere(
      (c) => c['id'] == selectedConversationId,
      orElse: () => {},
    );
    final otherParticipant = (conversation['participants'] as List?)
        ?.firstWhere((p) => p['user_id'] != widget.userId);
    final profile = otherParticipant?['profiles'];

    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    showConversationList = true;
                  });
                },
              ),
              CircleAvatar(
                backgroundImage: profile?['avatar_url'] != null
                    ? NetworkImage(profile!['avatar_url'])
                    : null,
                child: profile?['avatar_url'] == null
                    ? Text(profile?['full_name'][0].toUpperCase() ?? '?')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show chat options
                },
              ),
            ],
          ),
        ),
        // Messages list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message['sender_id'] == widget.userId;
              final showAvatar = index == 0 || 
                  messages[index - 1]['sender_id'] != message['sender_id'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe && showAvatar) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: message['sender']?['avatar_url'] != null
                            ? NetworkImage(message['sender']['avatar_url'])
                            : null,
                        child: message['sender']?['avatar_url'] == null
                            ? Text(message['sender']?['full_name'][0].toUpperCase() ?? '?')
                            : null,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          message['content'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    if (isMe && showAvatar) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: message['sender']?['avatar_url'] != null
                            ? NetworkImage(message['sender']['avatar_url'])
                            : null,
                        child: message['sender']?['avatar_url'] == null
                            ? Text(message['sender']?['full_name'][0].toUpperCase() ?? '?')
                            : null,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        // Message input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () {
                  // Handle file attachment
                },
              ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: sendMessage,
                icon: const Icon(Icons.send),
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showConversationList ? 'Messages' : 'Chat'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (showConversationList)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Show search
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : showConversationList
              ? _buildConversationList()
              : _buildChatScreen(),
      floatingActionButton: showConversationList
          ? FloatingActionButton(
              onPressed: () {
                // Show new conversation dialog
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.message, color: Colors.white),
            )
          : null,
    );
  }
} 