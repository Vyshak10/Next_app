import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      // First check profiles table
      final profileData = await supabase
          .from('profiles')
          .select('id, name, avatar_url, user_type, bio, location, website')
          .eq('id', widget.targetUserId)
          .maybeSingle();

      if (profileData != null) {
        // If user_type indicates startup, get additional startup data
        if (profileData['user_type'] == 'startup') {
          final startupData = await supabase
              .from('startups')
              .select('name, logo, description, industry, founded_year')
              .eq('id', widget.targetUserId)
              .maybeSingle();

          if (startupData != null) {
            setState(() {
              _userProfile = {
                ...profileData,
                'name': startupData['name'] ?? profileData['name'],
                'avatar_url': startupData['logo'] ?? profileData['avatar_url'],
                'description': startupData['description'],
                'industry': startupData['industry'],
                'founded_year': startupData['founded_year'],
              };
            });
            return;
          }
        }
        setState(() => _userProfile = profileData);
      }
    } catch (e) {
      print('Error loading user profile: $e');
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

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('User not found'),
        ),
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
                  // Cover Image
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
                  // Profile Image
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
                  // Name and Connection Button
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
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              if (_userProfile!['founded_year'] != null)
                                Text(
                                  'Founded ${_userProfile!['founded_year']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
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

                  // Bio/Description
                  if (_userProfile!['bio'] != null || _userProfile!['description'] != null)
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
                          _userProfile!['description'] ?? _userProfile!['bio'],
                          style: TextStyle(
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Location
                  if (_userProfile!['location'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              _userProfile!['location'],
                              style: TextStyle(
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Website
                  if (_userProfile!['website'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Website',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            // TODO: Launch website URL
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