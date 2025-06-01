import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  final String userId;
  final String? conversationId;

  const MessagesScreen({
    Key? key,
    required this.userId,
    this.conversationId,
  }) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();

  late RealtimeChannel _channel;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> profiles = [];
  String? selectedRecipientId;
  String? conversationId;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _setupRealtime();
  }

  @override
  void dispose() {
    _messageController.dispose();
    supabase.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      late PostgrestFilterBuilder query;

      if (conversationId == 'broadcast') {
        // Load broadcast messages (where receivers_id is NULL or matches current user)
        query = supabase
            .from('messages')
            .select()
            .or('receivers_id.is.null,receivers_id.eq.${widget.userId}');
      } else if (conversationId != null) {
        // Load conversation messages
        query = supabase
            .from('messages')
            .select()
            .eq('conversation_id', conversationId!);
      } else {
        return; // No conversation selected
      }

      final response = await query.order('created_at', ascending: true);

      setState(() {
        messages = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      debugPrint('Error loading messages: $error');
    }
  }

  Future<void> _loadProfiles() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, name')
          .neq('id', widget.userId); // exclude self

      setState(() {
        profiles = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      debugPrint('Error loading profiles: $error');
    }
  }

  void _setupRealtime() {
    _channel = supabase.channel('public:messages');

    _channel
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newMessage = payload.newRecord;
        if (newMessage['conversation_id'] == conversationId) {
          setState(() {
            messages.add(newMessage);
          });
        }
      },
    )
        .subscribe();
  }

  Future<void> _ensureConversationExists() async {
    if (selectedRecipientId == null) {
      // Broadcast conversation
      conversationId = 'broadcast';
      return;
    }

    // At this point, selectedRecipientId is guaranteed to be non-null
    final recipientId = selectedRecipientId!;

    try {
      // Check if conversation already exists between these two users
      final existingConversation = await supabase
          .from('conversations')
          .select('id')
          .or('and(user1_id.eq.${widget.userId},user2_id.eq.$recipientId),and(user1_id.eq.$recipientId,user2_id.eq.${widget.userId})')
          .maybeSingle();

      if (existingConversation != null) {
        conversationId = existingConversation['id'].toString();
      } else {
        // Create new conversation
        final newConversation = await supabase
            .from('conversations')
            .insert({
          'user1_id': widget.userId,
          'user2_id': recipientId,
          'last_message': '',
          'last_message_at': DateTime.now().toIso8601String(),
        })
            .select('id')
            .single();

        conversationId = newConversation['id'].toString();
      }
    } catch (error) {
      debugPrint('Error ensuring conversation exists: $error');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _ensureConversationExists();

      if (selectedRecipientId != null) {
        // Single user message
        await supabase.from('messages').insert({
          'conversation_id': conversationId == 'broadcast' ? null : conversationId,
          'senders_id': widget.userId,
          'receivers_id': selectedRecipientId,
          'content': text,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Update conversation's last message (only for non-broadcast)
        if (conversationId != null && conversationId != 'broadcast') {
          await supabase
              .from('conversations')
              .update({
            'last_message': text,
            'last_message_at': DateTime.now().toIso8601String(),
          })
              .eq('id', conversationId!);
        }
      } else {
        // Broadcast to all users (set receivers_id to null for broadcast)
        await supabase.from('messages').insert({
          'conversation_id': null, // Broadcast messages don't have conversation_id
          'senders_id': widget.userId,
          'receivers_id': null, // NULL means broadcast to all
          'content': text,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      _messageController.clear();
      await _loadMessages();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $error')),
        );
      }
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final isMe = msg['senders_id'] == widget.userId;
    final timestamp = DateTime.parse(msg['created_at']).toLocal();
    final timeString =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.green[400] : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft:
                isMe ? const Radius.circular(12) : const Radius.circular(0),
                bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(12),
              ),
            ),
            child: Text(
              msg['content'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeString,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(messages[index]);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  // Dropdown for recipient selection
                  DropdownButton<String>(
                    value: selectedRecipientId,
                    hint: const Text('Select recipient (optional)'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Send to all users'),
                      ),
                      ...profiles.map((profile) {
                        return DropdownMenuItem<String>(
                          value: profile['id'],
                          child: Text(profile['name'] ?? 'Unnamed'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) async {
                      setState(() {
                        selectedRecipientId = value;
                      });
                      await _ensureConversationExists();
                      await _loadMessages();
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        backgroundColor: Colors.green[400],
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}