import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  String email = '';
  String description = '';
  String? avatarUrl;
  String? bannerUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    setState(() {
      name = response['name'] ?? '';
      email = response['email'] ?? '';
      description = response['description'] ?? '';
      avatarUrl = response['avatar_url'];
      bannerUrl = response['banner_url'];
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final uploadedUrl = await _uploadImage(File(pickedFile.path), 'avatars/${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (uploadedUrl != null) {
        setState(() {
          avatarUrl = uploadedUrl;
        });
        _saveProfileUpdates();
      }
    }
  }

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final uploadedUrl = await _uploadImage(File(pickedFile.path), 'banners/${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (uploadedUrl != null) {
        setState(() {
          bannerUrl = uploadedUrl;
        });
        _saveProfileUpdates();
      }
    }
  }

  Future<String?> _uploadImage(File file, String path) async {
    final supabase = Supabase.instance.client;
    final response = await supabase.storage
        .from('media')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    if (response.isEmpty) return null;

    final publicUrl = supabase.storage.from('media').getPublicUrl(path);
    return publicUrl;
  }

  Future<void> _saveProfileUpdates() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'name': name,
      'email': email,
      'description': description,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
    });
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: _pickBannerImage,
          child: bannerUrl != null
              ? Image.network(bannerUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)
              : Container(height: 180, color: Colors.grey[300]),
        ),
        Positioned(
          bottom: -40,
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : const AssetImage('assets/avatar.jpg') as ImageProvider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GestureDetector(
            onTap: () async {
              final desc = await _showDescriptionEditor();
              if (desc != null) {
                setState(() => description = desc);
                _saveProfileUpdates();
              }
            },
            child: Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
      ],
    );
  }

  Future<String?> _showDescriptionEditor() async {
    final controller = TextEditingController(text: description);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Enter company description'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildProfileDetails(),
          ],
        ),
      ),
    );
  }
}
