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
  final ScrollController _scrollController = ScrollController();

  late RealtimeChannel _channel;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> profiles = [];
  String? selectedRecipientId;
  String? conversationId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _setupRealtime();
    // Load messages initially if a conversation is pre-selected
    if (widget.conversationId != null) {
      conversationId = widget.conversationId;
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    supabase.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> fetchedMessages = [];

      if (conversationId == 'broadcast') {
        // Load broadcast messages (where conversation_id is NULL)
        final response = await supabase
            .from('messages')
            .select('*')
            .isFilter('conversation_id', null)
            .order('created_at', ascending: true);

        fetchedMessages = List<Map<String, dynamic>>.from(response);
      } else if (conversationId != null && conversationId != 'broadcast') {
        // Load conversation messages for specific conversation
        final response = await supabase
            .from('messages')
            .select('*')
            .eq('conversation_id', conversationId!)
            .order('created_at', ascending: true);

        fetchedMessages = List<Map<String, dynamic>>.from(response);
      } else {
        // Load all messages where user is sender or receiver
        final response = await supabase
            .from('messages')
            .select('*')
            .or('senders_id.eq.${widget.userId},receivers_id.eq.${widget.userId},receivers_id.is.null')
            .order('created_at', ascending: true);

        fetchedMessages = List<Map<String, dynamic>>.from(response);
      }

      // Fetch sender names for all messages
      for (var message in fetchedMessages) {
        final senderId = message['senders_id'];
        if (senderId != null) {
          try {
            final senderProfile = await supabase
                .from('profiles')
                .select('name')
                .eq('id', senderId)
                .single();
            message['sender_name'] = senderProfile['name'] ?? 'Unknown';
          } catch (e) {
            message['sender_name'] = 'Unknown';
          }
        }
      }

      setState(() {
        messages = fetchedMessages;
        isLoading = false;
      });

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

    } catch (error) {
      debugPrint('Error loading messages: $error');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $error')),
        );
      }
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
    _channel = supabase.channel('messages_channel_${widget.userId}');

    _channel
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        final newMessage = Map<String, dynamic>.from(payload.newRecord);

        // Check if this message is relevant to current user
        bool shouldAddMessage = false;

        if (conversationId == 'broadcast' && newMessage['conversation_id'] == null) {
          // Broadcast message and we're viewing broadcast
          shouldAddMessage = true;
        } else if (conversationId != null && conversationId != 'broadcast' &&
            newMessage['conversation_id'] == conversationId) {
          // Direct conversation message
          shouldAddMessage = true;
        } else if (conversationId == null) {
          // No specific conversation selected, show if user is involved
          shouldAddMessage = newMessage['senders_id'] == widget.userId ||
              newMessage['receivers_id'] == widget.userId ||
              newMessage['receivers_id'] == null; // broadcast
        }

        if (shouldAddMessage) {
          // Fetch sender name for the new message
          final senderId = newMessage['senders_id'];
          if (senderId != null) {
            try {
              final senderProfile = await supabase
                  .from('profiles')
                  .select('name')
                  .eq('id', senderId)
                  .single();
              newMessage['sender_name'] = senderProfile['name'] ?? 'Unknown';
            } catch (e) {
              newMessage['sender_name'] = 'Unknown';
            }
          }

          setState(() {
            messages.add(newMessage);
          });

          // Scroll to bottom when new message arrives
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
    )
        .subscribe();
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

  Future<void> _ensureConversationExists() async {
    if (selectedRecipientId == null) {
      // Broadcast conversation
      conversationId = 'broadcast';
      return;
    }

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
          'last_message_time': DateTime.now().toIso8601String(),
        })
            .select('id')
            .single();

        conversationId = newConversation['id'].toString();
      }
    } catch (error) {
      debugPrint('Error ensuring conversation exists: $error');
      // If conversation creation fails, still allow messaging
      conversationId = 'temp_${widget.userId}_$recipientId';
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear the input immediately for better UX
    _messageController.clear();

    try {
      if (selectedRecipientId != null) {
        // Ensure conversation exists for direct messages
        await _ensureConversationExists();

        // Single user message
        await supabase.from('messages').insert({
          'conversation_id': conversationId == 'broadcast' ? null :
          (conversationId?.startsWith('temp_') == true ? null : conversationId),
          'senders_id': widget.userId,
          'receivers_id': selectedRecipientId,
          'content': text,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Update conversation's last message (only for non-broadcast and existing conversations)
        if (conversationId != null &&
            conversationId != 'broadcast' &&
            !conversationId!.startsWith('temp_')) {
          await supabase
              .from('conversations')
              .update({
            'last_message': text,
            'last_message_time': DateTime.now().toIso8601String(),
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

        conversationId = 'broadcast';
      }

    } catch (error) {
      debugPrint('Detailed error sending message: $error');
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

    final senderName = msg['sender_name'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && (selectedRecipientId == null || conversationId == 'broadcast'))
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                senderName,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF25D366) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(2),
                      bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['content'] ?? '',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            timeString,
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    if (selectedRecipientId == null) {
      return 'Broadcast Chat';
    } else {
      final selectedProfile = profiles.firstWhere(
            (profile) => profile['id'] == selectedRecipientId,
        orElse: () => {'name': 'Chat'},
      );
      return selectedProfile['name'] ?? 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp-like background
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: const Color(0xFF075E54), // WhatsApp green
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Recipient selection dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: DropdownButton<String>(
              value: selectedRecipientId,
              hint: const Text('Select recipient (leave empty for broadcast)'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('🌐 Broadcast to all users'),
                ),
                ...profiles.map((profile) {
                  return DropdownMenuItem<String>(
                    value: profile['id'],
                    child: Text('👤 ${profile['name'] ?? 'Unnamed'}'),
                  );
                }).toList(),
              ],
              onChanged: (value) async {
                setState(() {
                  selectedRecipientId = value;
                  messages.clear(); // Clear current messages
                });

                if (value == null) {
                  conversationId = 'broadcast';
                } else {
                  await _ensureConversationExists();
                }

                await _loadMessages();
              },
            ),
          ),

          // Messages list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(
              child: Text(
                'No messages yet. Start the conversation!',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(messages[index]);
              },
            ),
          ),

          // Message input
          Container(
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: selectedRecipientId == null
                                ? 'Broadcast message to all...'
                                : 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF25D366),
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}