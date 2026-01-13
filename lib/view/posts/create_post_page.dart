import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:next_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _tags = [];
  final List<XFile> _selectedImages = [];
  final _tagController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  Future<String?> uploadPostImageToSupabase(Uint8List imageBytes, String fileName) async {
    print('Uploading to Supabase: $fileName, bytes: ${imageBytes.length}');
    final storage = Supabase.instance.client.storage;
    final bucket = storage.from('post-images');
    try {
      await bucket.uploadBinary(fileName, imageBytes, fileOptions: FileOptions(upsert: true));
      final url = bucket.getPublicUrl(fileName);
      print('Supabase upload success, url: $url');
      return url;
    } catch (e) {
      print('Supabase upload error: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize Supabase (safe to call multiple times)
    Supabase.initialize(
      url: 'https://mcwngfebeexcugypioey.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1jd25nZmViZWV4Y3VneXBpb2V5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0ODk5NDgsImV4cCI6MjA2MzA2NTk0OH0.bgMmfmoZtYhUSTXTHafDNhzupfredSV0GvD5-drNgoQ',
    );
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // Upload images to Supabase Storage
      final List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final imageBytes = await image.readAsBytes();
        final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        print('Calling uploadPostImageToSupabase for $fileName');
        final supabaseUrl = await uploadPostImageToSupabase(imageBytes, fileName);
        if (supabaseUrl != null) {
          imageUrls.add(supabaseUrl);
        } else {
          print('Failed to upload image to Supabase');
        }
      }
      // Get user_id from arguments or set a placeholder
      String userId = '';
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['user_id'] != null) {
        userId = args['user_id'].toString();
      } else {
        userId = '6852'; // TODO: Replace with actual user id logic
      }
      // Create post
      final postData = {
        'user_id': userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'tags': _tags,
        'image_urls': imageUrls,
      };
      print('Post data being sent: $postData');
      await _apiService.createPost(postData);
      if (mounted) {
        Navigator.pop(context, true); // Signal success
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
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                        );
                      }).toList(),
                    ),
                    TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(labelText: 'Add Tag'),
                      onFieldSubmitted: (value) {
                        if (value.isNotEmpty && !_tags.contains(value)) {
                          setState(() => _tags.add(value));
                          _tagController.clear();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
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
                                  child: Image.network(
                                    _selectedImages[index].path,
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
                                    onPressed: () => setState(() => _selectedImages.removeAt(index)),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _createPost,
                      child: const Text('Create Post'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 