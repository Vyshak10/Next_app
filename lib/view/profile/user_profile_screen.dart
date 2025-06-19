import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../common_widget/connection_request.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String targetUserId;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.targetUserId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final secureStorage = const FlutterSecureStorage();
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await secureStorage.read(key: 'auth_token');
      if (token == null) throw Exception('Token not found');

      final url = 'https://indianrupeeservices.in/NEXT/backend/get_profile.php?id=${widget.targetUserId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('profile')) {
          setState(() {
            _userProfile = data['profile'];
            _userPosts = List<Map<String, dynamic>>.from(data['posts'] ?? []);
          });
        } else {
          throw Exception("Response JSON does not contain 'profile' key.");
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _launchWebsite(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    final isStartup = _userProfile!['user_type'] == 'startup';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _userProfile!['avatar_url'] != null
                      ? NetworkImage(_userProfile!['avatar_url'])
                      : null,
                  child: _userProfile!['avatar_url'] == null
                      ? Text(
                          _userProfile!['name'][0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _userProfile!['name'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              if (_userProfile!['role'] != null)
                Center(child: Text(_userProfile!['role'], style: const TextStyle(fontSize: 16))),
              const SizedBox(height: 16),
              ConnectionRequest(
                currentUserId: widget.userId,
                targetUserId: widget.targetUserId,
                targetUserName: _userProfile!['name'],
                targetUserAvatar: _userProfile!['avatar_url'],
                targetUserType: _userProfile!['user_type'],
              ),
              const SizedBox(height: 24),
              if (_userProfile!['description'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_userProfile!['description'], style: TextStyle(color: Colors.grey[800])),
                    const SizedBox(height: 16),
                  ],
                ),
              if (_userProfile!['location'] != null)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined),
                    const SizedBox(width: 8),
                    Text(_userProfile!['location']),
                  ],
                ),
              const SizedBox(height: 16),
              if (_userProfile!['website'] != null)
                InkWell(
                  onTap: () => _launchWebsite(_userProfile!['website']),
                  child: Row(
                    children: [
                      const Icon(Icons.link),
                      const SizedBox(width: 8),
                      Text(_userProfile!['website'], style: const TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (_userProfile!['pitch_video_url'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pitch Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Image.network(
                      'https://img.youtube.com/vi/${Uri.parse(_userProfile!['pitch_video_url']).queryParameters['v']}/0.jpg',
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ],
                )
              else
                const Text("No pitch video uploaded."),
              const SizedBox(height: 24),
              const Text('Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _userPosts.isEmpty
                  ? const Text("No posts yet")
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _userPosts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final post = _userPosts[index];
                        return Image.network(
                          post['image_url'],
                          fit: BoxFit.cover,
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
