// ✅ Corrected posts.dart with Supabase image upload integration

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onPostCreated;

  const CreatePostBottomSheet({super.key, required this.onPostCreated});

  @override
  State<CreatePostBottomSheet> createState() => _CreatePostBottomSheetState();
}

class _CreatePostBottomSheetState extends State<CreatePostBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Uint8List> _selectedImages = [];
  final List<String> _createdPostImageUrls = [];
  bool _isLoading = false;

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    final List<Uint8List> images = await Future.wait(pickedFiles.map((file) => file.readAsBytes()));
    setState(() => _selectedImages = images);
    }

  Future<List<String>> _uploadImagesToSupabase(List<Uint8List> images) async {
    final supabase = Supabase.instance.client;
    List<String> uploadedUrls = [];

    for (int i = 0; i < images.length; i++) {
      final imagePath = 'post_${DateTime.now().millisecondsSinceEpoch}_$i.png';

      final response = await supabase.storage.from('post-images').uploadBinary(
        imagePath,
        images[i],
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      if (response.isNotEmpty) {
        final publicUrl = supabase.storage.from('post-images').getPublicUrl(imagePath);
        uploadedUrls.add(publicUrl);
      } else {
        throw Exception('Failed to upload image $i');
      }
    }

    return uploadedUrls;
  }

  Future<void> _createPost() async {
    if (_titleController.text.trim().isEmpty && _descriptionController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to your post')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = await getAuthToken();

    try {
      final imageUrls = await _uploadImagesToSupabase(_selectedImages);

      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/create_post.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'tags': _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'image_urls': imageUrls
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          final post = responseData['post'];
          widget.onPostCreated(post);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${responseData['error']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 8),
          TextField(controller: _tagsController, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _pickImages, icon: const Icon(Icons.image), label: const Text('Pick Images')),
          const SizedBox(height: 12),
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_selectedImages[index], width: 100, height: 100, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          if (_isLoading) const CircularProgressIndicator(),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _isLoading ? null : _createPost, child: const Text('Post')),
        ],
      ),
    );
  }
}
