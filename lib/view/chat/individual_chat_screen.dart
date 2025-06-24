import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IndividualChatScreen extends StatefulWidget {
  final String userId;
  final String partnerId;

  const IndividualChatScreen({super.key, required this.userId, required this.partnerId});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  String? conversationId;
  String apiBase = "http://indianrupeeservices.in/NEXT/backend";

  @override
  void initState() {
    super.initState();
    _setupConversation();
  }

  Future<void> _setupConversation() async {
    final response = await http.post(
      Uri.parse('$apiBase/create_conversation.php'),
      body: {
        'user1_id': widget.userId,
        'user2_id': widget.partnerId,
      },
    );
    final data = json.decode(response.body);
    conversationId = data['conversation_id'].toString();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    if (conversationId == null) return;
    final response = await http.get(
      Uri.parse('$apiBase/get_messages.php?conversation_id=$conversationId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> messageList = json.decode(response.body);
      setState(() {
        messages = messageList.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty || conversationId == null) return;

    final response = await http.post(
      Uri.parse('$apiBase/send_message.php'),
      body: {
        'conversation_id': conversationId!,
        'senders_id': widget.userId,
        'receivers_id': widget.partnerId,
        'content': content,
      },
    );
    if (response.statusCode == 200) {
      messageController.clear();
      _fetchMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];
                final isMe = msg['sender_id'].toString() == widget.userId;
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe) SizedBox(width: 50), // Space for received messages
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[600] : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                                  bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                msg['created_at'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMe) SizedBox(width: 50), // Space for sent messages
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}