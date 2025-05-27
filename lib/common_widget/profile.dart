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
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
      if (mounted) {
        setState(() => profile = data);
      }
    } catch (e) {
      _showSnackBar('Failed to load profile: $e');
    }
  }

  Future<void> _loadPosts() async {
    try {
      final data = await supabase
          .from('posts')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);
      if (mounted && data != null) {
        setState(() => posts = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      _showSnackBar('Failed to load posts: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);
      final fileName = 'avatars/${widget.userId}.png';

      // Upload file
      await supabase.storage.from('avatars').upload(fileName, file,
          fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update profile table with new avatar URL
      await supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl})
          .eq('id', widget.userId);

      await _loadProfile();
      _showSnackBar('Avatar updated successfully!');
    } catch (e) {
      _showSnackBar('Failed to upload avatar: $e');
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    try {
      await supabase
          .from('profiles')
          .update({'notify_enabled': enabled}).eq('id', widget.userId);
      await _loadProfile();
    } catch (e) {
      _showSnackBar('Failed to update notifications: $e');
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
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name")),
              const SizedBox(height: 12),
              TextField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(labelText: "Role")),
              const SizedBox(height: 12),
              TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description")),
              const SizedBox(height: 12),
              TextField(
                  controller: skillCtrl,
                  decoration: const InputDecoration(labelText: "Skills/Stage")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await supabase.from('profiles').update({
                  'name': nameCtrl.text.trim(),
                  'role': roleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'skills': skillCtrl.text.trim(),
                }).eq('id', widget.userId);

                Navigator.pop(context);
                await _loadProfile();
                _showSnackBar('Profile updated successfully!');
              } catch (e) {
                _showSnackBar('Failed to update profile: $e');
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showPostDetail(Map<String, dynamic> post) {
    final imageUrls = List<String>.from(post['image_urls'] ?? []);
    final tags = List<String>.from(post['tags'] ?? []);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(post['title'] ?? 'Post'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrls.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrls[index],
                                  fit: BoxFit.cover,
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
                      const SizedBox(height: 16),
                      Text(
                        post['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (post['description'] != null && post['description'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(post['description']),
                        ),
                      if (tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfileDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
          await _loadPosts();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Center(
                child: GestureDetector(
                  onTap: _uploadAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: profile!['avatar_url'] != null &&
                            profile!['avatar_url'] != ''
                            ? NetworkImage(profile!['avatar_url'])
                            : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Profile Info
              Text(
                profile!['name'] ?? 'No Name',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                profile!['email'] ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),

              if (profile!['role'] != null && profile!['role'] != '')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile!['role'],
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              if (profile!['description'] != null && profile!['description'] != '')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    profile!['description'],
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),

              if (profile!['skills'] != null && profile!['skills'] != '')
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile!['skills']
                      .split(',')
                      .map<Widget>((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      skill.trim(),
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                  ))
                      .toList(),
                ),

              const SizedBox(height: 24),

              // Notification Toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text("Push Notifications"),
                  subtitle: const Text("Receive updates about new posts and activities"),
                  value: profile!['notify_enabled'] ?? false,
                  onChanged: _toggleNotifications,
                ),
              ),

              const SizedBox(height: 24),

              // Posts Section
              Row(
                children: [
                  const Icon(Icons.grid_view, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Posts (${posts.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Posts Grid
              posts.isEmpty
                  ? Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No posts yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        'Go to Posts tab to create your first post!',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
                  : GridView.builder(
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
                  final imageUrls = List<String>.from(post['image_urls'] ?? []);

                  return GestureDetector(
                    onTap: () => _showPostDetail(post),
                    child: Container(
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
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
                      )
                          : const Center(
                        child: Icon(Icons.image, size: 32, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}