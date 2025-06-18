import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onBackTap;

  const ProfileScreen({Key? key, required this.userId, required this.onBackTap}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? profile;
  List<dynamic> posts = [];
  bool isLoading = true;
  bool isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    final uri = Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_profile.php?id=${widget.userId}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profile = data['profile'];
          posts = data['posts'] ?? [];
          _nameController.text = profile?['name'] ?? '';
          _roleController.text = profile?['role'] ?? '';
          _bioController.text = profile?['description'] ?? '';
          _videoController.text = profile?['pitch_video_url'] ?? '';
          isLoading = false;
        });
      } else {
        _showSnackBar('Failed to load profile');
      }
    } catch (e) {
      _showSnackBar('Error loading data');
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> saveProfileChanges() async {
    final uri = Uri.parse("https://indianrupeeservices.in/NEXT/backend/update_profile.php");
    try {
      final response = await http.post(uri, body: {
        "id": widget.userId,
        "name": _nameController.text.trim(),
        "role": _roleController.text.trim(),
        "bio": _bioController.text.trim(),
        "pitch_video_url": _videoController.text.trim(),
      });

      if (response.statusCode == 200) {
        _showSnackBar("Profile updated");
        setState(() => isEditing = false);
        await fetchProfileData();
      } else {
        _showSnackBar("Failed to update profile");
      }
    } catch (e) {
      _showSnackBar("Error updating profile");
    }
  }

  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFFF5F5F5),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showSnackBar("Edit profile picture coming soon"),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: profile?['avatar_url'] != null
                ? NetworkImage(profile!['avatar_url'])
                : null,
            child: profile?['avatar_url'] == null
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(profile?['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(profile?['role'] ?? '', style: const TextStyle(color: Colors.grey)),
        Text(profile?['description'] ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() => isEditing = !isEditing),
          icon: Icon(isEditing ? Icons.cancel : Icons.edit),
          label: Text(isEditing ? "Cancel" : "Edit Profile"),
        ),
      ],
    );
  }

  Widget _buildPitchSection() {
    if (!isEditing && _videoController.text.isEmpty) {
      return const Text("No pitch video uploaded.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing)
          _buildEditableField("Pitch Video URL (YouTube ID only)", _videoController)
        else
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              "https://img.youtube.com/vi/${_videoController.text}/maxresdefault.jpg",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
            ),
          ),
      ],
    );
  }

  Widget _buildPostGrid() {
    return posts.isEmpty
        ? const Center(child: Text("No posts yet"))
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final post = posts[index];
              final imgList = post['image_urls'] ?? [];
              final img = (imgList is List && imgList.isNotEmpty) ? imgList[0] : post['image_url'];

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBackTap),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: saveProfileChanges,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (isEditing) _buildEditableField("Name", _nameController),
            if (isEditing) _buildEditableField("Role", _roleController),
            if (isEditing) _buildEditableField("Bio", _bioController, maxLines: 3),
            _buildSection("Pitch Video", _buildPitchSection()),
            const SizedBox(height: 20),
            _buildSection("Posts", _buildPostGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
