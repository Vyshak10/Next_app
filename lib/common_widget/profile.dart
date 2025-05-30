import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../view/settings/settings_screen.dart';

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
  double profileCompletion = 0.0;

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
        setState(() {
          profile = data;
          profileCompletion = _calculateProfileCompletion(data);
        });
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

  double _calculateProfileCompletion(Map<String, dynamic>? profileData) {
    if (profileData == null) return 0.0;

    int completedFields = 0;
    int totalFields = 5;

    if (profileData['name'] is String && (profileData['name'] as String).isNotEmpty) completedFields++; else if (profileData['name'] != null) completedFields++;
    if (profileData['role'] is String && (profileData['role'] as String).isNotEmpty) completedFields++; else if (profileData['role'] != null) completedFields++;
    if (profileData['description'] is String && (profileData['description'] as String).isNotEmpty) completedFields++; else if (profileData['description'] != null) completedFields++;
    if (profileData['skills'] is String && (profileData['skills'] as String).isNotEmpty) completedFields++; else if (profileData['skills'] != null) completedFields++;
    if (profileData['avatar_url'] is String && (profileData['avatar_url'] as String).isNotEmpty) completedFields++; else if (profileData['avatar_url'] != null) completedFields++;

    return completedFields / totalFields;
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            forceElevated: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadProfile();
                await _loadPosts();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _uploadAvatar,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: CircularProgressIndicator(
                                value: profileCompletion,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey[300],
                                color: Colors.blueAccent,
                              ),
                            ),
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: profile!['avatar_url'] != null &&
                                  profile!['avatar_url'] != ''
                                  ? NetworkImage(profile!['avatar_url'])
                                  : const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                            ),
                            Center(
                              child: Text(
                                '${(profileCompletion * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 80,
                              bottom: 5,
                              child: GestureDetector(
                                onTap: _editProfileDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            profile!['name'] ?? 'No Name',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
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
                          const SizedBox(height: 8),
                          Text(
                            'Profile Complete',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (profile!['description'] != null && profile!['description'] != '')
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About Me',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile!['description'],
                              textAlign: TextAlign.start,
                              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                            ),
                          ],
                        ),
                      ),

                    if (profile!['skills'] != null && profile!['skills'] != '')
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Skills / Stage',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
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
                          ],
                        ),
                      ),

                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SwitchListTile(
                          title: const Text("Push Notifications", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                          subtitle: const Text("Receive updates about new posts and activities", style: TextStyle(color: Colors.grey)),
                          value: profile!['notify_enabled'] ?? false,
                          onChanged: _toggleNotifications,
                          activeColor: Colors.blueAccent,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        const Icon(Icons.grid_view, size: 20, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          'Posts (${posts.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    posts.isEmpty
                        ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (_, index) {
                          final post = posts[index];
                          final imageUrls = List<String>.from(post['image_urls'] ?? []);

                          return GestureDetector(
                            onTap: () => _showPostDetail(post),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
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
          ),
        ],
      ),
    );
  }
}