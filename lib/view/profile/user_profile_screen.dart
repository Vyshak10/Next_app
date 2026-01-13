import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../common_widget/connection_request.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common_widget/animated_greeting_gradient_mixin.dart';

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

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin, AnimatedGreetingGradientMixin<UserProfileScreen> {
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
        appBar: AppBar(),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('User not found')),
      );
    }

    final isStartup = _userProfile!['user_type'] == 'startup';

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: gradientAnimationController,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      gradient: getGreetingGradient(
                        gradientBeginAnimation.value,
                        gradientEndAnimation.value,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
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
                        const SizedBox(height: 12),
                        Text(
                          _userProfile!['name'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black26, offset: Offset(0,2), blurRadius: 4)]),
                        ),
                        if (_userProfile!['role'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(_userProfile!['role'], style: const TextStyle(fontSize: 16, color: Colors.white70)),
                          ),
                        if (_userProfile!['user_type'] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              _userProfile!['user_type'].toString().toUpperCase(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
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
