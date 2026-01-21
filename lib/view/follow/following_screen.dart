import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const FollowingScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> following = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    currentUserId = await storage.read(key: 'user_id');
    await _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    setState(() => isLoading = true);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Dummy data for testing
    setState(() {
      following = [
        {
          'id': '10',
          'name': 'Startup Accelerator Hub',
          'avatar_url': '',
          'user_type': 'Company',
          'role': 'Business Incubator',
          'bio': 'Accelerating growth for early-stage startups with mentorship and resources.',
          'is_verified': true,
        },
        {
          'id': '11',
          'name': 'Emily Watson',
          'avatar_url': '',
          'user_type': 'Startup',
          'role': 'Co-Founder',
          'bio': 'Developing sustainable fashion solutions with blockchain technology.',
          'is_verified': false,
        },
        {
          'id': '12',
          'name': 'Future Fund Ventures',
          'avatar_url': '',
          'user_type': 'Company',
          'role': 'Venture Capital',
          'bio': 'Investing in tomorrow\'s unicorns today. Focus on AI and deep tech.',
          'is_verified': true,
        },
        {
          'id': '13',
          'name': 'Michael Zhang',
          'avatar_url': '',
          'user_type': 'Startup',
          'role': 'Founder & CEO',
          'bio': 'Building the future of education with immersive VR experiences.',
          'is_verified': true,
        },
        {
          'id': '14',
          'name': 'Green Energy Partners',
          'avatar_url': '',
          'user_type': 'Company',
          'role': 'Impact Investors',
          'bio': 'Funding renewable energy and climate tech startups worldwide.',
          'is_verified': false,
        },
        {
          'id': '15',
          'name': 'Lisa Kumar',
          'avatar_url': '',
          'user_type': 'Startup',
          'role': 'Chief Product Officer',
          'bio': 'Creating next-gen fintech solutions for emerging markets.',
          'is_verified': true,
        },
      ];
      isLoading = false;
    });
    
    /* 
    // Original API call - uncomment when backend is ready
    try {
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_following.php?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            following = List<Map<String, dynamic>>.from(data['following'] ?? []);
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching following: $e');
      setState(() => isLoading = false);
    }
    */
  }

  Future<void> _unfollowUser(String targetUserId) async {
    if (currentUserId == null) return;

    final shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfollow'),
        content: const Text('Are you sure you want to unfollow this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );

    if (shouldUnfollow != true) return;

    try {
      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/toggle_follow.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'follower_id': currentUserId,
          'following_id': targetUserId,
          'action': 'unfollow',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Remove from local list
          setState(() {
            following.removeWhere((f) => f['id'].toString() == targetUserId);
          });
          
          _showSnackBar('Unfollowed successfully');
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Following',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : following.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchFollowing,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: following.length,
                    itemBuilder: (context, index) {
                      return _buildFollowingCard(following[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildFollowingCard(Map<String, dynamic> user) {
    final isCurrentUser = user['id'].toString() == currentUserId;
    final avatarUrl = user['avatar_url'];
    final hasAvatar = avatarUrl != null && avatarUrl.toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              backgroundImage: hasAvatar ? CachedNetworkImageProvider(avatarUrl) : null,
              child: !hasAvatar
                  ? Icon(
                      Icons.person,
                      size: 28,
                      color: Colors.grey[400],
                    )
                  : null,
            ),
            if (user['is_verified'] == true)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.blueAccent,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['name'] ?? 'Unknown User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user['user_type'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user['user_type'].toString().toLowerCase().contains('startup')
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user['user_type'].toString().toLowerCase().contains('startup')
                          ? Icons.rocket_launch
                          : Icons.business,
                      size: 12,
                      color: user['user_type'].toString().toLowerCase().contains('startup')
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user['user_type'].toString().split(' ').first,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: user['user_type'].toString().toLowerCase().contains('startup')
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user['role'] != null && user['role'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  user['role'],
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (user['bio'] != null && user['bio'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  user['bio'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: !isCurrentUser && widget.userId == currentUserId
            ? SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () => _unfollowUser(user['id'].toString()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_remove, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Unfollow',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Not Following Anyone',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start following startups and companies\nto see them here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
