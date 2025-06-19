import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _tags = [];
  final List<File> _selectedImages = [];
  final _tagController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

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
    setState(() => _isLoading = true);
    try {
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
      appBar: AppBar(title: const Text('Create Post')),
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