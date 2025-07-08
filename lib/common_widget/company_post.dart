import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// import 'package:share_plus/share_plus.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final token = await getAuthToken();

    try {
      print('Loading posts...'); // Debug log
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_posts.php'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Decoded data: $data'); // Debug log

        if (data['success'] == true && data['posts'] != null) {
          setState(() {
            _posts = List<Map<String, dynamic>>.from(data['posts']);
            print('Posts loaded: ${_posts.length}'); // Debug log

            // Initialize like status for each post
            for (var post in _posts) {
              // Use the values from API or set defaults
              post['isLiked'] = post['isLiked'] ?? false;
              post['likeCount'] = post['likeCount'] ?? 0;
              post['comments'] = post['comments'] ?? <Map<String, dynamic>>[];

              // Handle image_urls - ensure it's a list
              if (post['image_urls'] is String && post['image_urls'].isNotEmpty) {
                try {
                  post['image_urls'] = jsonDecode(post['image_urls']);
                } catch (e) {
                  post['image_urls'] = [];
                }
              } else if (post['image_urls'] == null) {
                post['image_urls'] = [];
              }

              // Handle tags - ensure it's a list
              if (post['tags'] is String && post['tags'].isNotEmpty) {
                try {
                  post['tags'] = jsonDecode(post['tags']);
                } catch (e) {
                  post['tags'] = [];
                }
              } else if (post['tags'] == null) {
                post['tags'] = [];
              }
            }
          });
        } else {
          print('API returned success: false or no posts'); // Debug log
        }
      } else {
        print('HTTP Error: ${response.statusCode}'); // Debug log
      }
    } catch (e) {
      print('Error loading posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading posts: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(int postIndex) async {
    final post = _posts[postIndex];
    final token = await getAuthToken();

    // Optimistic update
    setState(() {
      post['isLiked'] = !post['isLiked'];
      post['likeCount'] = post['isLiked'] ? post['likeCount'] + 1 : post['likeCount'] - 1;
    });

    try {
      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/toggle_like.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'post_id': post['id'],
        }),
      );

      if (response.statusCode != 200) {
        // Revert on error
        setState(() {
          post['isLiked'] = !post['isLiked'];
          post['likeCount'] = post['isLiked'] ? post['likeCount'] + 1 : post['likeCount'] - 1;
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        post['isLiked'] = !post['isLiked'];
        post['likeCount'] = post['isLiked'] ? post['likeCount'] + 1 : post['likeCount'] - 1;
      });
      print('Error toggling like: $e');
    }
  }

  void _showCommentsBottomSheet(int postIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsBottomSheet(
        postId: _posts[postIndex]['id'].toString(),
        comments: _posts[postIndex]['comments'],
        onCommentAdded: (newComment) {
          setState(() {
            _posts[postIndex]['comments'].add(newComment);
          });
        },
      ),
    );
  }

  void _showCreatePostBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreatePostBottomSheet(
        onPostCreated: (newPost) {
          setState(() {
            _posts.insert(0, newPost); // Add new post at the beginning
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // No title
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.post_add, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No posts yet'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return PostCard(
              post: _posts[index],
              onLikePressed: () => _toggleLike(index),
              onCommentPressed: () => _showCommentsBottomSheet(index),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostBottomSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CreatePostBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onPostCreated;

  const CreatePostBottomSheet({
    Key? key,
    required this.onPostCreated,
  }) : super(key: key);

  @override
  State<CreatePostBottomSheet> createState() => _CreatePostBottomSheetState();
}

class _CreatePostBottomSheetState extends State<CreatePostBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isLoading = false;

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((xfile) => File(xfile.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (_titleController.text.trim().isEmpty &&
        _descriptionController.text.trim().isEmpty &&
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to your post')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = await getAuthToken();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/create_post.php'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();

      // Parse tags
      String tagsText = _tagsController.text.trim();
      if (tagsText.isNotEmpty) {
        List<String> tags = tagsText.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
        request.fields['tags'] = jsonEncode(tags);
      }

      // Add images
      for (int i = 0; i < _selectedImages.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            _selectedImages[i].path,
          ),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['success']) {
          widget.onPostCreated(responseData['post']);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['error']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Text(
                  'Create Post',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _createPost,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Post title (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),

                  // Tags field
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      hintText: 'Tags (separate with commas)',
                      border: OutlineInputBorder(),
                      helperText: 'e.g., travel, food, photography',
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),

                  // Image picker button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo),
                      label: Text(_selectedImages.isEmpty ? 'Add Photos' : 'Change Photos'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected images preview
                  if (_selectedImages.isNotEmpty) ...[
                    const Text(
                      'Selected Photos:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_selectedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;

  const PostCard({
    Key? key,
    required this.post,
    required this.onLikePressed,
    required this.onCommentPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: post['avatar_url'] != null && post['avatar_url'].isNotEmpty
                  ? NetworkImage(post['avatar_url'])
                  : null,
              child: post['avatar_url'] == null || post['avatar_url'].isEmpty
                  ? Text((post['author_name'] ?? 'U')[0].toUpperCase())
                  : null,
            ),
            title: Text(
              post['author_name'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _formatDate(post['created_at']),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),

          // Post content
          if (post['title'] != null && post['title'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post['title'].toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          if (post['description'] != null && post['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(post['description'].toString()),
            ),

          // Images
          if (post['image_urls'] != null &&
              post['image_urls'] is List &&
              (post['image_urls'] as List).isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: (post['image_urls'] as List).length,
                itemBuilder: (context, imgIndex) {
                  final url = (post['image_urls'] as List)[imgIndex];
                  if (url != null && url.toString().isNotEmpty) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset('assets/img/default_post.png', fit: BoxFit.cover);
                        },
                      ),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset('assets/img/default_post.png', fit: BoxFit.cover),
                    );
                  }
                },
              ),
            ),

          // Tags
          if (post['tags'] != null &&
              post['tags'] is List &&
              (post['tags'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: (post['tags'] as List).map<Widget>((tag) {
                  return Chip(
                    label: Text(tag.toString()),
                    backgroundColor: Colors.blue[100],
                    labelStyle: TextStyle(color: Colors.blue[800], fontSize: 12),
                  );
                }).toList(),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                AnimatedRocketLike(
                  isLiked: post['isLiked'] ?? false,
                  onTap: onLikePressed,
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: onCommentPressed,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.comment_outlined, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Comment',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (post['likeCount'] != null && post['likeCount'] > 0)
                  Text(
                    '${post['likeCount']} likes',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }
}

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final List<Map<String, dynamic>> comments;
  final Function(Map<String, dynamic>) onCommentAdded;

  const CommentsBottomSheet({
    Key? key,
    required this.postId,
    required this.comments,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final token = await getAuthToken();

    try {
      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/add_comment.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'post_id': widget.postId,
          'body': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          widget.onCommentAdded(responseData['comment']);
          _commentController.clear();
        }
      }
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
            child: widget.comments.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
              itemCount: widget.comments.length,
              itemBuilder: (context, index) {
                final comment = widget.comments[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundImage: comment['avatar_url'] != null && comment['avatar_url'].isNotEmpty
                        ? NetworkImage(comment['avatar_url'])
                        : null,
                    child: comment['avatar_url'] == null || comment['avatar_url'].isEmpty
                        ? Text((comment['author_name'] ?? 'U')[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    comment['author_name'] ?? 'Unknown User',
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
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _addComment,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.send, color: Colors.blue),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyPostScreen extends StatefulWidget {
  const CompanyPostScreen({Key? key}) : super(key: key);

  @override
  State<CompanyPostScreen> createState() => _CompanyPostScreenState();
}

class _CompanyPostScreenState extends State<CompanyPostScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final token = await getAuthToken();

    try {
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_posts.php'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['posts'] != null) {
          setState(() {
            _posts = List<Map<String, dynamic>>.from(data['posts']);
            for (var post in _posts) {
              post['isLiked'] = post['isLiked'] ?? false;
              post['likeCount'] = post['likeCount'] ?? 0;
              post['comments'] = post['comments'] ?? <Map<String, dynamic>>[];
              if (post['image_urls'] is String && post['image_urls'].isNotEmpty) {
                try {
                  post['image_urls'] = jsonDecode(post['image_urls']);
                } catch (e) {
                  post['image_urls'] = [];
                }
              } else if (post['image_urls'] == null) {
                post['image_urls'] = [];
              }
              if (post['tags'] is String && post['tags'].isNotEmpty) {
                try {
                  post['tags'] = jsonDecode(post['tags']);
                } catch (e) {
                  post['tags'] = [];
                }
              } else if (post['tags'] == null) {
                post['tags'] = [];
              }
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading posts: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sharePost(Map<String, dynamic> post) {
    final text = '${post['title'] ?? ''}\n${post['description'] ?? ''}';
    // TODO: Implement sharing using share_plus
    // Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Posts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.post_add, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No posts yet'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (post['image_urls'] != null && post['image_urls'].isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: PageView.builder(
                                itemCount: post['image_urls'].length,
                                itemBuilder: (context, imgIdx) {
                                  return Image.network(
                                    post['image_urls'][imgIdx],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                                  );
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text(post['description'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: (post['tags'] as List).map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.thumb_up, color: Colors.blueAccent, size: 20),
                                    const SizedBox(width: 4),
                                    Text('${post['likeCount']}'),
                                    const SizedBox(width: 16),
                                    Icon(Icons.comment, color: Colors.grey, size: 20),
                                    const SizedBox(width: 4),
                                    Text('${post['comments'].length}'),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.share, color: Colors.blueAccent),
                                      onPressed: () => _sharePost(post),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}