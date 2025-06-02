import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  Timer? _timeUpdateTimer;
  final ImagePicker _picker = ImagePicker();

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
    // Start timer for updating message times every 30 seconds for more noticeable changes during testing
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        // Adding a print statement to confirm timer is firing
        debugPrint('Timer fired: Updating message times');
        setState(() {});
      }
    });
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
    _timeUpdateTimer?.cancel();
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

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );
      }

      // Upload image to Supabase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final File imageFile = File(image.path);
      
      await supabase.storage.from('message_images').upload(fileName, imageFile);
      final String imageUrl = supabase.storage.from('message_images').getPublicUrl(fileName);

      // Send message with image URL
      if (selectedRecipientId != null) {
        await _ensureConversationExists();
        await supabase.from('messages').insert({
          'conversation_id': conversationId == 'broadcast' ? null :
          (conversationId?.startsWith('temp_') == true ? null : conversationId),
          'senders_id': widget.userId,
          'receivers_id': selectedRecipientId,
          'content': '[Image]',
          'image_url': imageUrl,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await supabase.from('messages').insert({
          'conversation_id': null,
          'senders_id': widget.userId,
          'receivers_id': null,
          'content': '[Image]',
          'image_url': imageUrl,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    }
  }

  String _getRelativeTime(String? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final messageTime = DateTime.parse(timestamp).toLocal();
    final difference = now.difference(messageTime);

    if (difference.inSeconds < 10) { // More granular update for very recent messages
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago'; // Changed to full word
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? 'Yesterday' : '$days days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      return DateFormat('MMM d, y').format(messageTime);
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final isMe = msg['senders_id'] == widget.userId;
    final timestamp = msg['created_at'];
    final timeString = _getRelativeTime(timestamp);
    final isRecent = DateTime.now().difference(DateTime.parse(timestamp)).inMinutes < 5;
    final hasImage = msg['image_url'] != null;

    final senderName = msg['sender_name'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && (selectedRecipientId == null || conversationId == 'broadcast'))
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                    child: Text(
                      senderName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    senderName,
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          )
                        : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isMe ? const Color(0xFF2196F3) : Colors.black)
                            .withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            msg['image_url'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.error_outline),
                                ),
                              );
                            },
                          ),
                        ),
                      if (msg['content'] != null && msg['content'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            msg['content'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isRecent && isMe)
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            timeString,
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.grey[600],
                              fontSize: 11,
                              fontWeight: isRecent ? FontWeight.w500 : FontWeight.normal,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: selectedRecipientId,
                hint: Text(
                  selectedRecipientId == null ? 'Broadcast Chat' : 'Select recipient',
                  style: const TextStyle(color: Color(0xFF1976D2)),
                  overflow: TextOverflow.ellipsis,
                ),
                isExpanded: true,
                underline: Container(),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1976D2)),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.public, color: Color(0xFF2196F3), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Broadcast to all users',
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...profiles.map((profile) {
                    return DropdownMenuItem<String>(
                      value: profile['id'],
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                              child: Text(
                                (profile['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile['name'] ?? 'Unnamed',
                              style: const TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) async {
                  setState(() {
                    selectedRecipientId = value;
                    messages.clear();
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
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF2196F3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading messages...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 72,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageItem(messages[index]);
                        },
                      ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: selectedRecipientId == null
                                    ? 'Broadcast message to all...'
                                    : 'Type a message...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              maxLines: null,
                              minLines: 1,
                              keyboardType: TextInputType.multiline,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.image, color: Color(0xFF1976D2)),
                            onPressed: _pickAndSendImage,
                            tooltip: 'Send Image',
                            splashRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.rocket_launch, color: Colors.white),
                      onPressed: _sendMessage,
                      tooltip: 'Send Message',
                      splashRadius: 24,
                    ),
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