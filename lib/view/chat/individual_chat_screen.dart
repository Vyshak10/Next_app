import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Assume _getUserProfile function is available or needs to be added/accessed
// from a shared utility or directly implemented here.
// For now, let's include a simplified version or assume access if it exists elsewhere.
// If _getUserProfile is in messages.dart and needs to be truly shared, consider moving it.
// For this screen, we might need user profile for the current user (to display messages) and partner profile for the header.

class IndividualChatScreen extends StatefulWidget {
  final String userId; // Current user's ID
  final String partnerId; // ID of the chat partner (user or company)

  const IndividualChatScreen({
    super.key,
    required this.userId,
    required this.partnerId,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  final TextEditingController messageController = TextEditingController();
  String? _conversationId; // Will store the ID of the conversation
  Map<String, dynamic>? _chatPartnerProfile; // Profile of the person/company being chatted with
  RealtimeChannel? _messageChannel; // Make nullable and initialize to null
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _findOrCreateConversation();
    _fetchChatPartnerProfile(); // Fetch partner profile for the header
  }

  @override
  void dispose() {
    messageController.dispose();
    _messageChannel?.unsubscribe();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to find an existing conversation or create a new one
  Future<void> _findOrCreateConversation() async {
    setState(() => isLoading = true);
    try {
      // Attempt to find an existing conversation between the two participants
      final existingConversations = await supabase
          .from('conversations')
          .select('id') // Select only the conversation ID first
          .contains('participants', [{'user_id': widget.userId}, {'user_id': widget.partnerId}])
          .limit(1); // Limit to 1 as we expect at most one direct conversation

      if (existingConversations.isNotEmpty) {
        // Found existing conversation
        _conversationId = existingConversations[0]['id'];
        print('Found existing conversation: $_conversationId');
      } else {
        // No existing conversation, create a new one
        print('No existing conversation, creating new one...');
        final newConversation = await supabase
            .from('conversations')
            .insert({})
            .select('id')
            .single();

        _conversationId = newConversation['id'];

        // Add participants to the new conversation
        await supabase.from('conversation_participants').insert([
          {'conversation_id': _conversationId, 'user_id': widget.userId},
          {'conversation_id': _conversationId, 'user_id': widget.partnerId},
        ]);
        print('Created new conversation: $_conversationId');
      }

      // After finding or creating the conversation, load messages and subscribe
      if (_conversationId != null) {
        fetchMessages();
        subscribeToMessages(); // Subscribe *after* conversationId is set
      }
    } catch (e) {
      print('Error finding or creating conversation: $e');
      // Handle error (e.g., show error message)
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Function to fetch messages for the current conversation
  Future<void> fetchMessages() async {
    if (_conversationId == null) return; // Cannot fetch messages without conversation ID

    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('messages')
          .select('*, sender:profiles!sender_id(full_name, avatar_url)') // Corrected join syntax with explicit foreign key
          .eq('conversation_id', _conversationId!) // Use null-assertion operator
          .order('created_at', ascending: true);

      if (mounted && response != null) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(response);
        });
        // Scroll to bottom after messages are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      print('Error fetching messages: $e');
    } finally {
       setState(() => isLoading = false);
    }
  }

    // Function to fetch the chat partner's profile
  Future<void> _fetchChatPartnerProfile() async {
    // This is a placeholder. You should use the actual _getUserProfile function
    // from your utilities or implement it here if it's not globally accessible.
    // For now, we'll set a dummy profile or rely on the joined data in messages if possible.
    // A proper implementation would fetch the partner's profile using widget.partnerId.
    // Let's use the _getUserProfile logic we used previously, which needs to be available.

    // Assuming _getUserProfile is accessible or implemented here:
     try {
      final profile = await _getUserProfile(widget.partnerId);
      if (mounted) {
        setState(() {
          _chatPartnerProfile = profile;
        });
      }
    } catch (e) {
      print('Error fetching chat partner profile: $e');
       if (mounted) {
        setState(() {
          _chatPartnerProfile = null; // Ensure it's null on error
        });
      }
    }
  }

  void subscribeToMessages() {
    // Cannot subscribe without conversation ID
    if (_conversationId == null) {
      print('Cannot subscribe: conversationId is null.'); // Added logging
      return;
    }

    // Unsubscribe from previous channel if any
    _messageChannel?.unsubscribe(); // Use null-aware access for unsubscribe

    _messageChannel = supabase.channel('conversation:' + _conversationId!); // Simpler channel naming

    _messageChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: _conversationId!), // Filter by conversation ID
      callback: (payload) {
        final newMessage = payload.newRecord;
        // Fetch the full message with sender profile after insertion
        _fetchAndAddMessage(newMessage?['id']);
      },
    ).subscribe(); // Subscribe to the channel
  }

    // Fetch a single new message by ID and add it to the list
  Future<void> _fetchAndAddMessage(String? messageId) async {
      if (messageId == null) return;
      try {
          final newMessage = await supabase
              .from('messages')
              .select('*, sender:profiles(full_name, avatar_url)')
              .eq('id', messageId)
              .single();

          if (mounted && newMessage != null) {
              setState(() {
                  messages.add(newMessage);
              });
              // Scroll to the bottom after adding new message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                      );
                  }
              });
          }
      } catch (e) {
          print('Error fetching and adding new message: $e');
      }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty || _conversationId == null) return;

    try {
      await supabase.from('messages').insert({
        'conversation_id': _conversationId,
        'sender_id': widget.userId,
        'receiver_id': widget.partnerId, // Assuming direct message for now
        'content': messageController.text.trim(),
      });

      messageController.clear();
      // Message will be added to the list via Realtime subscription (_fetchAndAddMessage)
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Helper to format time (can reuse from MessagesScreen if available)
  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.parse(timestamp).toLocal(); // Convert to local time
    final now = DateTime.now().toLocal();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date); // Include year for older messages
    }
  }

  // Function to fetch user or company profile (Copied from previous _getUserProfile logic)
   Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      // First check profiles table
      final profileData = await supabase
          .from('profiles')
          .select('full_name, avatar_url, user_type') // Ensure these columns exist
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        if (profileData['user_type'] == 'startup') {
          final startupData = await supabase
              .from('startups')
              .select('name as full_name, logo as avatar_url') // Ensure name and logo exist in startups
              .eq('id', userId)
              .maybeSingle();

          if (startupData != null) {
            return {
              'full_name': startupData['full_name'] ?? profileData['full_name'],
              'avatar_url': startupData['avatar_url'] ?? profileData['avatar_url'],
              'user_type': 'startup',
            };
          }
        }
        return profileData; // Return regular profile data
      }

      // Fallback: check startups table directly if not found in profiles
      final startupData = await supabase
          .from('startups')
          .select('name as full_name, logo as avatar_url') // Ensure name and logo exist in startups
          .eq('id', userId)
          .maybeSingle();

      if (startupData != null) {
        return {
          'full_name': startupData['full_name'],
          'avatar_url': startupData['avatar_url'],
          'user_type': 'startup',
        };
      }

      return null; // Not found
    } catch (e) {
      print('Error in _getUserProfile: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        titleSpacing: 0, // Remove default title spacing
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
             CircleAvatar(
              radius: 18, // Slightly smaller avatar in app bar
              backgroundImage: _chatPartnerProfile?['avatar_url'] != null
                  ? NetworkImage(_chatPartnerProfile!['avatar_url'])
                  : null,
              child: _chatPartnerProfile?['avatar_url'] == null
                  ? Text(
                      _chatPartnerProfile?['full_name']?.isNotEmpty == true ? _chatPartnerProfile!['full_name'][0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _chatPartnerProfile?['full_name'] ?? 'Loading...', // Use fetched name or placeholder
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert), // More options
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List with background
          Expanded(
            child: Container(
              color: Colors.blueGrey[50], // Using a soft color as placeholder
              child: isLoading // Use local isLoading for messages
                  ? const Center(child: CircularProgressIndicator()) // Show loading indicator
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _buildMessageBubble(message); // Use existing bubble builder
                      },
                    ),
            ),
          ),
          // Message input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // Use theme card color
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), // Softer shadow
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, // Align items at the bottom
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file, color: Colors.grey[600]), // Attachment icon
                  onPressed: () {
                    // TODO: Handle file attachment
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4), // Add some horizontal padding
                    child: TextField(
                      controller: messageController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    // Reusing the message bubble builder from MessagesScreen (can be made a separate widget if reused widely)
   Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender_id'] == widget.userId;
    final time = _formatTime(message['created_at']);

    // Use the sender's profile info included in the message data from the Supabase join
    final senderProfile = message['sender'] as Map<String, dynamic>?;
    final senderAvatarUrl = senderProfile?['avatar_url'];
    final senderName = senderProfile?['full_name'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 12 : 0),
            topRight: Radius.circular(isMe ? 0 : 12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['content'],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }



} 