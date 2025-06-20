import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PostScreen extends StatefulWidget {
  final String userId;

  const PostScreen({super.key, required this.userId});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<String?> getAuthToken() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_token');
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final token = await getAuthToken();

    try {
      final response = await http.get(
        Uri.parse('https://yourdomain.com/api/posts/${widget.userId}/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _comments = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final token = await getAuthToken();

    final response = await http.post(
      Uri.parse('https://yourdomain.com/api/posts/${widget.userId}/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'body': _commentController.text.trim(),
      }),
    );

    if (response.statusCode == 201) {
      _commentController.clear();
      _loadComments();
    } else {
      print('Failed to post comment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final profile = comment['user_profile'];

                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundImage: profile?['avatar_url'] != null
                        ? NetworkImage(profile['avatar_url'])
                        : null,
                    child: profile?['avatar_url'] == null
                        ? Text((profile?['name'] ?? 'U')[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    profile?['name'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(comment['body'] ?? ''),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedRocketLike extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const AnimatedRocketLike({
    Key? key,
    required this.isLiked,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedRocketLike> createState() => AnimatedRocketLikeState();
}

class AnimatedRocketLikeState extends State<AnimatedRocketLike> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _wasLiked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _wasLiked = widget.isLiked;
  }

  @override
  void didUpdateWidget(covariant AnimatedRocketLike oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != _wasLiked) {
      if (widget.isLiked) {
        _controller.forward(from: 0.0);
      }
      _wasLiked = widget.isLiked;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Icon(
                  widget.isLiked ? Icons.rocket_launch_rounded : Icons.rocket_launch_outlined,
                  color: widget.isLiked ? Colors.orange : Colors.grey[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Like',
                style: TextStyle(
                  color: widget.isLiked ? Colors.orange : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: widget.isLiked ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
