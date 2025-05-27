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

  // Load all posts for feed (excluding current user's posts)
  Future<void> _loadFeedPosts() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('posts')
          .select('''
            *,
            profiles:user_id (
              name,
              avatar_url
            )
          ''')
          .neq('user_id', widget.userId)
          .order('created_at', ascending: false);

      if (mounted && data != null) {
        setState(() => _feedPosts = List<Map<String, dynamic>>.from(data));
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
          final profile = post['profiles'];
          final imageUrls = List<String>.from(post['image_urls'] ?? []);
          final tags = List<String>.from(post['tags'] ?? []);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Header
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profile?['avatar_url'] != null
                        ? NetworkImage(profile['avatar_url'])
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  title: Text(profile?['name'] ?? 'Unknown User'),
                  subtitle: Text(_formatDate(post['created_at'])),
                ),

                // Post Images
                if (imageUrls.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, imgIndex) {
                        return Image.network(
                          imageUrls[imgIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 50),
                            );
                          },
                        );
                      },
                    ),
                  ),

                // Post Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (post['description'] != null && post['description'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(post['description']),
                        ),
                      if (tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: tags.map((tag) {
                              return Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 12)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
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