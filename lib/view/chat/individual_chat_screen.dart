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
  final String apiUrl = "https://indianrupeeservices.in/NEXT/backend/api"; // Replace this

  @override
  void initState() {
    super.initState();
    _setupConversation();
  }

  Future<void> _setupConversation() async {
    final response = await http.post(
      Uri.parse('$apiUrl/chat/conversation'),
      body: {
        'user_id': widget.userId,
        'partner_id': widget.partnerId,
      },
    );

    final data = json.decode(response.body);
    conversationId = data['conversation_id'].toString();

    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final response = await http.get(Uri.parse('$apiUrl/chat/messages/$conversationId'));

    if (response.statusCode == 200) {
      final List<dynamic> messageList = json.decode(response.body);
      setState(() {
        messages = messageList.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    // Dummy: alternate sender for demo
    final isMe = messages.isEmpty || (messages.last['sender_id'] != widget.userId);
    final newMessage = {
      'sender_id': isMe ? widget.userId : widget.partnerId,
      'receiver_id': isMe ? widget.partnerId : widget.userId,
      'content': content,
      'created_at': DateTime.now().toString(),
    };
    setState(() {
      messages.add(newMessage);
      messageController.clear();
    });
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
                return ListTile(
                  title: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg['content'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                    ),
                  ),
                  subtitle: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      msg['created_at'] ?? '',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: messageController, decoration: InputDecoration(hintText: 'Type message...'))),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
