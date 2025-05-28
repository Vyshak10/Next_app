import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostScreen extends StatefulWidget {
  final String userId;

  const PostScreen({super.key, required this.userId});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  late TabController _tabController;

  // Create Post Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final List<String> _tags = [];

  // Feed Data
  List<Map<String, dynamic>> _feedPosts = [];
  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeedPosts();
    _loadMyPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // Get user profile data from appropriate table
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      // First check profiles table
      final profileData = await supabase
          .from('profiles')
          .select('name, avatar_url, user_type')
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        // If user_type indicates startup, get additional startup data
        if (profileData['user_type'] == 'startup') {
          final startupData = await supabase
              .from('startups')
              .select('name as startup_name, logo')
              .eq('id', userId)
              .maybeSingle();

          if (startupData != null) {
            return {
              'name': startupData['startup_name'] ?? profileData['name'],
              'avatar_url': startupData['logo'] ?? profileData['avatar_url'],
              'user_type': 'startup',
            };
          }
        }
        return profileData;
      }

      // If not found in profiles, check startups table directly
      final startupData = await supabase
          .from('startups')
          .select('name, logo')
          .eq('id', userId)
          .maybeSingle();

      if (startupData != null) {
        return {
          'name': startupData['name'],
          'avatar_url': startupData['logo'],
          'user_type': 'startup',
        };
      }

      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Load all posts for feed with proper user data
  Future<void> _loadFeedPosts() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('posts')
          .select('*')
          .neq('user_id', widget.userId)
          .order('created_at', ascending: false);

      if (mounted && data != null) {
        List<Map<String, dynamic>> postsWithProfiles = [];

        for (var post in data) {
          final userProfile = await _getUserProfile(post['user_id']);
          post['user_profile'] = userProfile;
          postsWithProfiles.add(post);
        }

        setState(() => _feedPosts = postsWithProfiles);
      }
    } catch (e) {
      _showSnackBar('Failed to load feed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Load current user's posts
  Future<void> _loadMyPosts() async {
    try {
      final data = await supabase
          .from('posts')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      if (mounted && data != null) {
        setState(() => _myPosts = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      _showSnackBar('Failed to load your posts: $e');
    }
  }

  // Toggle like functionality
  Future<void> _toggleLike(String postId, bool isLiked) async {
    try {
      if (isLiked) {
        // Remove like
        await supabase
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', widget.userId);
      } else {
        // Add like
        await supabase.from('likes').insert({
          'post_id': postId,
          'user_id': widget.userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Refresh feed to update like count
      _loadFeedPosts();
    } catch (e) {
      _showSnackBar('Failed to update like: $e');
    }
  }

  // Get like count and check if current user liked
  Future<Map<String, dynamic>> _getLikeData(String postId) async {
    try {
      final likes = await supabase
          .from('likes')
          .select('user_id')
          .eq('post_id', postId);

      final likeCount = likes.length;
      final isLiked = likes.any((like) => like['user_id'] == widget.userId);

      return {'count': likeCount, 'isLiked': isLiked};
    } catch (e) {
      return {'count': 0, 'isLiked': false};
    }
  }

  // Show comments bottom sheet
  void _showCommentsSheet(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: postId,
        userId: widget.userId,
      ),
    );
  }

  // Pick multiple images
  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  // Remove image by index
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Add tag
  void _addTag(String tag) {
    tag = tag.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
    _tagController.clear();
  }

  // Remove tag
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // Upload images to Supabase storage
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final file = File(_selectedImages[i].path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'posts/${widget.userId}/post_${timestamp}_$i.png';

      await supabase.storage.from('posts').upload(fileName, file,
          fileOptions: const FileOptions(upsert: true));

      final imageUrl = supabase.storage.from('posts').getPublicUrl(fileName);
      imageUrls.add(imageUrl);
    }

    return imageUrls;
  }

  // Create new post
  Future<void> _createPost() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a title');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      await supabase.from('posts').insert({
        'user_id': widget.userId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_urls': imageUrls,
        'tags': _tags,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _selectedImages.clear();
      _tags.clear();

      _showSnackBar('Post created successfully!');

      // Reload posts
      await _loadMyPosts();
      await _loadFeedPosts();

    } catch (e) {
      _showSnackBar('Failed to create post: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildCreatePostTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Post',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Title Field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Post Title *',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Image Selection
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.image),
            label: const Text('Add Images'),
          ),
          const SizedBox(height: 16),

          // Selected Images Preview
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Description Field
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Tell us about your post...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Tags Field
          TextField(
            controller: _tagController,
            onSubmitted: _addTag,
            decoration: const InputDecoration(
              labelText: 'Add tags (press Enter)',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Tags Display
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // Create Post Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Post', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isLoading && _feedPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feedPosts.isEmpty) {
      return const Center(
        child: Text('No posts to show yet!', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeedPosts,
      child: ListView.builder(
        itemCount: _feedPosts.length,
        itemBuilder: (context, index) {
          final post = _feedPosts[index];
          final userProfile = post['user_profile'];
          final imageUrls = List<String>.from(post['image_urls'] ?? []);
          final tags = List<String>.from(post['tags'] ?? []);

          return FutureBuilder<Map<String, dynamic>>(
            future: _getLikeData(post['id'].toString()),
            builder: (context, snapshot) {
              final likeData = snapshot.data ?? {'count': 0, 'isLiked': false};

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Header
                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: userProfile?['avatar_url'] != null
                            ? NetworkImage(userProfile['avatar_url'])
                            : null,
                        child: userProfile?['avatar_url'] == null
                            ? Text(
                          (userProfile?['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),
                      title: Text(
                        userProfile?['name'] ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(_formatDate(post['created_at'])),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {
                          // Show more options
                        },
                      ),
                    ),

                    // Post Images
                    if (imageUrls.isNotEmpty)
                      Container(
                        height: 400,
                        child: PageView.builder(
                          itemCount: imageUrls.length,
                          itemBuilder: (context, imgIndex) {
                            return GestureDetector(
                              onDoubleTap: () {
                                _toggleLike(post['id'].toString(), likeData['isLiked']);
                              },
                              child: Image.network(
                                imageUrls[imgIndex],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, size: 50),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    // Action Buttons (Like, Comment, Share)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleLike(post['id'].toString(), likeData['isLiked']),
                            child: Icon(
                              likeData['isLiked'] ? Icons.favorite : Icons.favorite_border,
                              color: likeData['isLiked'] ? Colors.red : Colors.black,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _showCommentsSheet(post['id'].toString()),
                            child: const Icon(Icons.chat_bubble_outline, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.send_outlined, size: 28),
                          const Spacer(),
                          const Icon(Icons.bookmark_border, size: 28),
                        ],
                      ),
                    ),

                    // Like Count
                    if (likeData['count'] > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${likeData['count']} ${likeData['count'] == 1 ? 'like' : 'likes'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                    // Post Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: '${userProfile?['name'] ?? 'Unknown User'} ',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: post['title'] ?? ''),
                              ],
                            ),
                          ),
                          if (post['description'] != null && post['description'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(post['description']),
                            ),
                          if (tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: tags.map((tag) {
                                  return Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // View Comments
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: GestureDetector(
                        onTap: () => _showCommentsSheet(post['id'].toString()),
                        child: const Text(
                          'View all comments',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMyPostsGrid() {
    if (_myPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text('Create your first post!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index];
        final imageUrls = List<String>.from(post['image_urls'] ?? []);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[300],
          ),
          child: imageUrls.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image);
              },
            ),
          )
              : const Icon(Icons.image, size: 32),
        );
      },
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
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.feed), text: 'Feed'),
            Tab(icon: Icon(Icons.add), text: 'Create'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          _buildCreatePostTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _tabController.animateTo(1); // Switch to Create tab
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Post',
      ),
    );
  }
}

// Comments Bottom Sheet Widget
class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final String userId;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      // Try to load comments - if table doesn't exist, handle gracefully
      final data = await supabase
          .from('comments')
          .select('*')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false);

      if (mounted && data != null) {
        List<Map<String, dynamic>> commentsWithProfiles = [];

        for (var comment in data) {
          final userProfile = await _getUserProfile(comment['user_id']);
          comment['user_profile'] = userProfile;
          commentsWithProfiles.add(comment);
        }

        setState(() => _comments = commentsWithProfiles);
      }
    } catch (e) {
      print('Error loading comments: $e');
      // If comments table doesn't exist, show empty state
      setState(() => _comments = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Get user profile data from appropriate table (same as parent class)
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      // First check profiles table
      final profileData = await supabase
          .from('profiles')
          .select('name, avatar_url, user_type')
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        // If user_type indicates startup, get additional startup data
        if (profileData['user_type'] == 'startup') {
          final startupData = await supabase
              .from('startups')
              .select('name as startup_name, logo')
              .eq('id', userId)
              .maybeSingle();

          if (startupData != null) {
            return {
              'name': startupData['startup_name'] ?? profileData['name'],
              'avatar_url': startupData['logo'] ?? profileData['avatar_url'],
              'user_type': 'startup',
            };
          }
        }
        return profileData;
      }

      // If not found in profiles, check startups table directly
      final startupData = await supabase
          .from('startups')
          .select('name, logo')
          .eq('id', userId)
          .maybeSingle();

      if (startupData != null) {
        return {
          'name': startupData['name'],
          'avatar_url': startupData['logo'],
          'user_type': 'startup',
        };
      }

      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await supabase.from('comments').insert({
        'post_id': widget.postId,
        'user_id': widget.userId,
        'body': _commentController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      _commentController.clear();
      _loadComments();
    } catch (e) {
      print('Error adding comment: $e');
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

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const Divider(),

          // Comments List
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

          // Comment Input
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
