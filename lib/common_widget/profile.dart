import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPosts();
  }

  Future<void> _loadProfile() async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', widget.userId)
        .single();
    if (mounted) {
      setState(() => profile = data);
    }
  }

  Future<void> _loadPosts() async {
    final data = await supabase
        .from('posts')
        .select()
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);
    if (mounted && data != null) {
      setState(() => posts = List<Map<String, dynamic>>.from(data));
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      final fileName = 'avatars/${widget.userId}.png';

      // Upload file - returns String file path, no error property
      await supabase.storage.from('avatars').upload(fileName, file,
          fileOptions: const FileOptions(upsert: true));

      // Get public URL - returns String URL
      final avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update profile table with new avatar URL
      await supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl})
          .eq('id', widget.userId);

      await _loadProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e')));
    }
  }

  Future<void> _uploadPostImage() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'posts/${widget.userId}/post_$timestamp.png';

      await supabase.storage.from('posts').upload(fileName, file,
          fileOptions: const FileOptions(upsert: true));

      final postUrl = supabase.storage.from('posts').getPublicUrl(fileName);

      await supabase.from('posts').insert({
        'user_id': widget.userId,
        'image_url': postUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload post image: $e')));
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    try {
      await supabase
          .from('profiles')
          .update({'notify_enabled': enabled}).eq('id', widget.userId);
      await _loadProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update notifications: $e')));
    }
  }

  void _editProfileDialog() {
    final nameCtrl = TextEditingController(text: profile?['name']);
    final roleCtrl = TextEditingController(text: profile?['role']);
    final descCtrl = TextEditingController(text: profile?['description']);
    final skillCtrl = TextEditingController(text: profile?['skills']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name")),
              TextField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(labelText: "Role")),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: "Description")),
              TextField(
                  controller: skillCtrl,
                  decoration: const InputDecoration(labelText: "Stage")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await supabase.from('profiles').update({
                  'name': nameCtrl.text,
                  'role': roleCtrl.text,
                  'description': descCtrl.text,
                  'skills': skillCtrl.text,
                }).eq('id', widget.userId);
                Navigator.pop(context);
                await _loadProfile();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: $e')));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editProfileDialog),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_a_photo),
        onPressed: _uploadPostImage,
        tooltip: 'Add Post',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploadAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profile!['avatar_url'] != null &&
                    profile!['avatar_url'] != ''
                    ? NetworkImage(profile!['avatar_url'])
                    : const AssetImage('assets/default_avatar.png')
                as ImageProvider,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
              child: Text(profile!['name'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Center(
              child: Text(profile!['email'] ?? '',
                  style: const TextStyle(color: Colors.grey))),
          if (profile!['role'] != null && profile!['role'] != '')
            Center(child: Text("Role: ${profile!['role']}")),
          const SizedBox(height: 10),
          if (profile!['description'] != null && profile!['description'] != '')
            Text(profile!['description']),
          const SizedBox(height: 10),
          if (profile!['skills'] != null && profile!['skills'] != '')
            Wrap(
              spacing: 8,
              children: profile!['skills']
                  .split(',')
                  .map<Widget>((skill) => Chip(label: Text(skill.trim())))
                  .toList(),
            ),
          const Divider(height: 30),
          SwitchListTile(
            title: const Text("Notifications Enabled"),
            value: profile!['notify_enabled'] ?? false,
            onChanged: _toggleNotifications,
          ),
          const SizedBox(height: 20),
          const Divider(),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: posts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (_, index) {
              final post = posts[index];
              return Image.network(post['image_url'], fit: BoxFit.cover);
            },
          ),
        ],
      ),
    );
  }
}
