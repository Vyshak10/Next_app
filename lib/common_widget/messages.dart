import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final storage = const FlutterSecureStorage();
  Timer? _timeUpdateTimer;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> profiles = [];
  String? selectedRecipientId;
  String? conversationId;
  bool isLoading = false;

  final String apiUrl = 'https://yourdomain.com/backend2/api';

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
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
    super.dispose();
  }

  Future<String?> getAuthToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> _loadProfiles() async {
    final token = await getAuthToken();
    final response = await http.get(
      Uri.parse('$apiUrl/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        profiles = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    }
  }

  Future<void> _loadMessages() async {
    if (isLoading || conversationId == null) return;
    setState(() => isLoading = true);
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$apiUrl/messages/$conversationId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        messages = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _ensureConversationExists() async {
    if (selectedRecipientId == null) return;
    final token = await getAuthToken();

    final response = await http.post(
      Uri.parse('$apiUrl/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({
        'user1_id': widget.userId,
        'user2_id': selectedRecipientId
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      conversationId = data['id'].toString();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final token = await getAuthToken();

    await _ensureConversationExists();

    final response = await http.post(
      Uri.parse('$apiUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({
        'conversation_id': conversationId,
        'senders_id': widget.userId,
        'receivers_id': selectedRecipientId,
        'content': text
      }),
    );

    if (response.statusCode == 201) {
      _loadMessages();
    }
  }

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final token = await getAuthToken();

    await _ensureConversationExists();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/messages/image'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['conversation_id'] = conversationId ?? '';
    request.fields['senders_id'] = widget.userId;
    request.fields['receivers_id'] = selectedRecipientId ?? '';
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode == 201) {
      _loadMessages();
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

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final isMe = msg['senders_id'] == widget.userId;
    final createdAt = DateTime.tryParse(msg['created_at'] ?? '');

    return ListTile(
      title: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[200] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: msg['image_url'] != null
              ? Image.network(msg['image_url'], width: 200)
              : Text(msg['content'] ?? ''),
        ),
      ),
      subtitle: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          createdAt != null ? DateFormat.jm().format(createdAt) : '',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageItem(msg);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
