import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post.dart';
import '../../services/api_service.dart';
import 'post_card.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({Key? key}) : super(key: key);

  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<Post> _posts = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _tags = [];
  final List<File> _selectedImages = [];
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final response = await _apiService.getPosts();
      setState(() {
        _posts = response.map((json) => Post.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // Upload images first
      final List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final imageBytes = await image.readAsBytes();
        final response = await _apiService.multipartRequest(
          'upload_post_image.php',
          {},
          {'image': imageBytes},
        );
        imageUrls.add(response['image_url']);
      }

      // Create post
      final postData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'tags': _tags,
        'image_urls': imageUrls,
      };

      await _apiService.createPost(postData);
      await _loadPosts();

      // Reset form
      _titleController.clear();
      _descriptionController.clear();
      _tags.clear();
      _selectedImages.clear();
      _tagController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _likePost(String postId) async {
    try {
      await _apiService.likePost(postId);
      _loadPosts(); // Reload posts to get updated like count
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking post: $e')),
        );
      }
    }
  }

  Future<void> _addComment(String postId, String comment) async {
    try {
      await _apiService.addComment(postId, comment);
      _loadPosts(); // Reload posts to get updated comments
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Post'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Tags
                Wrap(
                  spacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() => _tags.remove(tag));
                      },
                    );
                  }).toList(),
                ),
                TextFormField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    labelText: 'Add Tag',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty && !_tags.contains(value)) {
                      setState(() => _tags.add(value));
                      _tagController.clear();
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Images
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Image.file(
                                _selectedImages[index],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Images'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createPost();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePostDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return PostCard(
              post: _posts[index],
              onTap: () {
                // TODO: Navigate to post detail page
              },
              onTagTap: (tag) {
                // TODO: Filter posts by tag
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }
} 