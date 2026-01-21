import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> followers = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    currentUserId = await storage.read(key: 'user_id');
    await _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_followers.php?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            followers = List<Map<String, dynamic>>.from(data['followers'] ?? []);
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching followers: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow(String targetUserId, bool isFollowing) async {
    if (currentUserId == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/toggle_follow.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'follower_id': currentUserId,
          'following_id': targetUserId,
          'action': isFollowing ? 'unfollow' : 'follow',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update local state
          setState(() {
            final index = followers.indexWhere((f) => f['id'].toString() == targetUserId);
            if (index != -1) {
              followers[index]['is_following'] = !isFollowing;
            }
          });
          
          _showSnackBar(isFollowing ? 'Unfollowed successfully' : 'Following now');
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
              'Followers',
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
          : followers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchFollowers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: followers.length,
                    itemBuilder: (context, index) {
                      return _buildFollowerCard(followers[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildFollowerCard(Map<String, dynamic> follower) {
    final isCurrentUser = follower['id'].toString() == currentUserId;
    final isFollowing = follower['is_following'] ?? false;
    final avatarUrl = follower['avatar_url'];
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
            if (follower['is_verified'] == true)
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
                follower['name'] ?? 'Unknown User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (follower['user_type'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: follower['user_type'].toString().toLowerCase().contains('startup')
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      follower['user_type'].toString().toLowerCase().contains('startup')
                          ? Icons.rocket_launch
                          : Icons.business,
                      size: 12,
                      color: follower['user_type'].toString().toLowerCase().contains('startup')
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      follower['user_type'].toString().split(' ').first,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: follower['user_type'].toString().toLowerCase().contains('startup')
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
            if (follower['role'] != null && follower['role'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  follower['role'],
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (follower['bio'] != null && follower['bio'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  follower['bio'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: isCurrentUser
            ? null
            : SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () => _toggleFollow(follower['id'].toString(), isFollowing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey[200] : Colors.blueAccent,
                    foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFollowing ? Icons.person_remove : Icons.person_add,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFollowing ? 'Unfollow' : 'Follow',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Followers Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When people follow this profile,\nthey\'ll appear here',
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
