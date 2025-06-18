import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../common_widget/connection_request.dart';

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

      final url = 'https://indianrupeeservices.in/NEXT/backend/api/user-profile/${widget.targetUserId}';
      print('🔗 Fetching from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('profile')) {
          setState(() => _userProfile = data['profile']);
        } else {
          throw Exception("Response JSON does not contain 'profile' key.");
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error loading user profile: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade700,
                          Colors.blue.shade500,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
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
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile!['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isStartup) ...[
                              Text(
                                _userProfile!['industry'] ?? 'Industry not specified',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                              if (_userProfile!['founded_date'] != null)
                                Text(
                                  'Founded ${_userProfile!['founded_date']}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                            ],
                          ],
                        ),
                      ),
                      ConnectionRequest(
                        currentUserId: widget.userId,
                        targetUserId: widget.targetUserId,
                        targetUserName: _userProfile!['name'],
                        targetUserAvatar: _userProfile!['avatar_url'],
                        targetUserType: _userProfile!['user_type'],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_userProfile!['description'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isStartup ? 'About' : 'Bio',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userProfile!['description'],
                          style: TextStyle(color: Colors.grey[800], height: 1.5),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  if (_userProfile!['office_location'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              _userProfile!['office_location'],
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  if (_userProfile!['website'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Website',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            // TODO: Add URL launcher
                          },
                          child: Row(
                            children: [
                              Icon(Icons.link, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                _userProfile!['website'],
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
