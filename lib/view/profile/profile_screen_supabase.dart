import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/post_service.dart';

/// Modern Profile Screen with Supabase Integration and Follow System
class ProfileScreenSupabase extends StatefulWidget {
  final String? userId; // If null, shows current user's profile
  final VoidCallback? onBackTap;

  const ProfileScreenSupabase({
    super.key,
    this.userId,
    this.onBackTap,
  });

  @override
  State<ProfileScreenSupabase> createState() => _ProfileScreenSupabaseState();
}

class _ProfileScreenSupabaseState extends State<ProfileScreenSupabase>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final PostService _postService = PostService();

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isMyProfile = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showError('Please log in to view profiles');
        return;
      }

      // Determine which profile to load
      final profileUserId = widget.userId ?? currentUser.id;
      _isMyProfile = profileUserId == currentUser.id;

      // Load profile
      final profile = await _profileService.getUserProfile(profileUserId);
      if (profile == null) {
        _showError('Profile not found');
        return;
      }

      // Load user's posts
      final posts = await _postService.getUserPosts(profileUserId);

      setState(() {
        _profile = profile;
        _posts = posts;
        _isFollowing = profile['is_following'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading profile: $e');
      _showError('Failed to load profile');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null) return;

    setState(() => _isFollowLoading = true);

    try {
      final success = _isFollowing
          ? await _profileService.unfollowUser(_profile!['id'])
          : await _profileService.followUser(_profile!['id']);

      if (success) {
        setState(() {
          _isFollowing = !_isFollowing;
          final currentCount = _profile!['followers_count'] ?? 0;
          _profile!['followers_count'] =
              _isFollowing ? currentCount + 1 : currentCount - 1;
        });

        _showSuccess(_isFollowing ? 'Following!' : 'Unfollowed');
      } else {
        _showError('Failed to update follow status');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isFollowLoading = false);
    }
  }

  void _showFollowers() {
    if (_profile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersListScreen(userId: _profile!['id']),
      ),
    );
  }

  void _showFollowing() {
    if (_profile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowingListScreen(userId: _profile!['id']),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: widget.onBackTap != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBackTap,
                )
              : null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: widget.onBackTap != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBackTap,
                )
              : null,
        ),
        body: const Center(child: Text('Profile not found')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              leading: widget.onBackTap != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBackTap,
                    )
                  : null,
              actions: [
                if (_isMyProfile)
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      // Navigate to settings
                    },
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF6366F1),
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
                    Tab(icon: Icon(Icons.info_outline), text: 'About'),
                    Tab(icon: Icon(Icons.business), text: 'Company'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildAboutTab(),
            _buildCompanyTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 47,
                backgroundImage: _profile!['avatar_url'] != null
                    ? NetworkImage(_profile!['avatar_url'])
                    : null,
                child: _profile!['avatar_url'] == null
                    ? Text(
                        (_profile!['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              _profile!['name'] ?? _profile!['email'] ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Role
            if (_profile!['role'] != null)
              Text(
                _profile!['role'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  _posts.length.toString(),
                  'Posts',
                  () {},
                ),
                _buildStatItem(
                  (_profile!['followers_count'] ?? 0).toString(),
                  'Followers',
                  _showFollowers,
                ),
                _buildStatItem(
                  (_profile!['following_count'] ?? 0).toString(),
                  'Following',
                  _showFollowing,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (!_isMyProfile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isFollowLoading ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isFollowing ? Colors.white : const Color(0xFF6366F1),
                          foregroundColor:
                              _isFollowing ? const Color(0xFF6366F1) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: _isFollowing
                                ? const BorderSide(color: Color(0xFF6366F1))
                                : BorderSide.none,
                          ),
                        ),
                        child: _isFollowLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isFollowing ? 'Following' : 'Follow'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Message functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.message),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final imageUrls = List<String>.from(post['image_urls'] ?? []);

        return GestureDetector(
          onTap: () {
            // Show post details
          },
          child: Container(
            color: Colors.grey[200],
            child: imageUrls.isNotEmpty
                ? Image.network(
                    imageUrls[0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, color: Colors.grey);
                    },
                  )
                : Center(
                    child: Text(
                      post['title'] ?? post['description'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_profile!['description'] != null) ...[
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_profile!['description']),
          const SizedBox(height: 16),
        ],
        if (_profile!['skills'] != null) ...[
          const Text(
            'Skills',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ((_profile!['skills'] as List?) ?? [])
                .map((skill) => Chip(label: Text(skill.toString())))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (_profile!['website'] != null) ...[
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Website'),
            subtitle: Text(_profile!['website']),
            onTap: () {
              // Launch URL
            },
          ),
        ],
        if (_profile!['email'] != null) ...[
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(_profile!['email']),
          ),
        ],
      ],
    );
  }

  Widget _buildCompanyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_profile!['company_name'] != null) ...[
          const Text(
            'Company',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_profile!['company_name']),
          const SizedBox(height: 16),
        ],
        const Center(
          child: Text('Company information coming soon'),
        ),
      ],
    );
  }
}

// Followers List Screen
class FollowersListScreen extends StatelessWidget {
  final String userId;

  const FollowersListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: profileService.getFollowers(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final followers = snapshot.data ?? [];

          if (followers.isEmpty) {
            return const Center(child: Text('No followers yet'));
          }

          return ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final follower = followers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: follower['avatar_url'] != null
                      ? NetworkImage(follower['avatar_url'])
                      : null,
                  child: follower['avatar_url'] == null
                      ? Text((follower['name'] ?? 'U')[0].toUpperCase())
                      : null,
                ),
                title: Text(follower['name'] ?? 'Unknown'),
                subtitle: Text(follower['role'] ?? follower['email'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreenSupabase(userId: follower['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Following List Screen
class FollowingListScreen extends StatelessWidget {
  final String userId;

  const FollowingListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: profileService.getFollowing(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final following = snapshot.data ?? [];

          if (following.isEmpty) {
            return const Center(child: Text('Not following anyone yet'));
          }

          return ListView.builder(
            itemCount: following.length,
            itemBuilder: (context, index) {
              final user = following[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  child: user['avatar_url'] == null
                      ? Text((user['name'] ?? 'U')[0].toUpperCase())
                      : null,
                ),
                title: Text(user['name'] ?? 'Unknown'),
                subtitle: Text(user['role'] ?? user['email'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreenSupabase(userId: user['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Helper class for sticky tab bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
