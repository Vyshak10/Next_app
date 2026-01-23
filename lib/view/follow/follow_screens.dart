import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen to show list of followers
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
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    final cleanId = widget.userId.trim();
    final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(cleanId);

    if (cleanId.isEmpty || !isUuid) {
      print('⚠️ Cannot load followers: userId "$cleanId" is empty or not a valid UUID');
      setState(() {
        _followers = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch follower IDs from Supabase
      final followsResponse = await Supabase.instance.client
          .from('follows')
          .select('follower_id, created_at')
          .eq('following_id', cleanId)
          .order('created_at', ascending: false);
      
      print('📊 Found ${followsResponse.length} follow records for ${widget.userId}');

      // Fetch profile data for each follower
      List<Map<String, dynamic>> followersList = [];
      
      for (var follow in followsResponse) {
        try {
          final profileResponse = await Supabase.instance.client
              .from('profiles')
              .select('id, name, email, avatar_url, role')
              .eq('id', follow['follower_id'])
              .single();

          followersList.add({
            'id': profileResponse['id'],
            'name': profileResponse['name'] ?? profileResponse['email'] ?? 'Unknown User',
            'email': profileResponse['email'] ?? '',
            'avatar_url': profileResponse['avatar_url'],
            'role': profileResponse['role'] ?? '',
            'followed_at': follow['created_at'],
          });
        } catch (e) {
          print('⚠️ Could not fetch profile for ${follow['follower_id']}: $e');
        }
      }

      setState(() {
        _followers = followersList;
        _isLoading = false;
      });

      print('✅ Loaded ${_followers.length} followers');
    } catch (e) {
      print('❌ Error loading followers: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading followers: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName}\'s Followers'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _followers.length,
                  itemBuilder: (context, index) {
                    final follower = _followers[index];
                    return _buildFollowerTile(follower);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No followers yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When people follow ${widget.userName},\nthey\'ll appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerTile(Map<String, dynamic> follower) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: const Color(0xFF6366F1),
        backgroundImage: follower['avatar_url'] != null
            ? NetworkImage(follower['avatar_url'])
            : null,
        child: follower['avatar_url'] == null
            ? Text(
                (follower['name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        follower['name'] ?? 'Unknown User',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        follower['role']?.isNotEmpty == true
            ? follower['role']
            : follower['email'] ?? '',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Navigate to follower's profile
        // You can implement this to show the user's profile
        print('Tapped on follower: ${follower['id']}');
      },
    );
  }
}

/// Screen to show list of users being followed
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
  List<Map<String, dynamic>> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final cleanId = widget.userId.trim();
    final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(cleanId);

    if (cleanId.isEmpty || !isUuid) {
      print('⚠️ Cannot load following: userId "$cleanId" is empty or not a valid UUID');
      setState(() {
        _following = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch following IDs from Supabase
      final followsResponse = await Supabase.instance.client
          .from('follows')
          .select('following_id, created_at')
          .eq('follower_id', cleanId)
          .order('created_at', ascending: false);
      
      print('📊 Found ${followsResponse.length} following records for ${widget.userId}');

      // Fetch profile data for each user being followed
      List<Map<String, dynamic>> followingList = [];
      
      for (var follow in followsResponse) {
        try {
          final profileResponse = await Supabase.instance.client
              .from('profiles')
              .select('id, name, email, avatar_url, role')
              .eq('id', follow['following_id'])
              .single();

          followingList.add({
            'id': profileResponse['id'],
            'name': profileResponse['name'] ?? profileResponse['email'] ?? 'Unknown User',
            'email': profileResponse['email'] ?? '',
            'avatar_url': profileResponse['avatar_url'],
            'role': profileResponse['role'] ?? '',
            'followed_at': follow['created_at'],
          });
        } catch (e) {
          print('⚠️ Could not fetch profile for ${follow['following_id']}: $e');
        }
      }

      setState(() {
        _following = followingList;
        _isLoading = false;
      });

      print('✅ Loaded ${_following.length} following');
    } catch (e) {
      print('❌ Error loading following: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading following: $e')),
        );
      }
    }
  }

  Future<void> _unfollowUser(String userId, String userName) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      await Supabase.instance.client
          .from('follows')
          .delete()
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unfollowed $userName')),
        );
      }

      // Reload the list
      _loadFollowing();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unfollowing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName}\'s Following'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _following.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _following.length,
                  itemBuilder: (context, index) {
                    final user = _following[index];
                    return _buildFollowingTile(user);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Not following anyone yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find people to follow and\nthey\'ll appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiscoverUsersScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('Discover Users'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingTile(Map<String, dynamic> user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: const Color(0xFF6366F1),
        backgroundImage: user['avatar_url'] != null
            ? NetworkImage(user['avatar_url'])
            : null,
        child: user['avatar_url'] == null
            ? Text(
                (user['name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user['name'] ?? 'Unknown User',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        user['role']?.isNotEmpty == true
            ? user['role']
            : user['email'] ?? '',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: TextButton(
        onPressed: () => _unfollowUser(user['id'], user['name']),
        child: const Text('Unfollow'),
      ),
      onTap: () {
        // Navigate to user's profile
        print('Tapped on user: ${user['id']}');
      },
    );
  }
}

/// Screen to discover and follow new users
class DiscoverUsersScreen extends StatefulWidget {
  final String? currentUserId;
  const DiscoverUsersScreen({super.key, this.currentUserId});

  @override
  State<DiscoverUsersScreen> createState() => _DiscoverUsersScreenState();
}

class _DiscoverUsersScreenState extends State<DiscoverUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Set<String> _followingIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final String? currentUserId = widget.currentUserId ?? Supabase.instance.client.auth.currentUser?.id;
      
      print('🔍 DISCOVER USERS: Starting to load users...');
      print('🔍 Current User ID: $currentUserId');
      
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = Supabase.instance.client
          .from('profiles')
          .select('id, name, email, avatar_url, role, description');

      // Fetch users
      print('🔍 Executing Supabase query...');
      final List<Map<String, dynamic>> usersResponse;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        print('🔍 Excluding current user: $currentUserId');
        usersResponse = await query.neq('id', currentUserId).limit(50);
      } else {
        print('🔍 Loading ALL users (no exclusion)');
        usersResponse = await query.limit(50);
      }
      
      print('🔍 Query returned ${usersResponse.length} rows');
      print('🔍 First user: ${usersResponse.isNotEmpty ? usersResponse[0] : "NONE"}');

      // Fetch users that current user is following
      List<dynamic> followingResponse = [];
      if (currentUserId != null && currentUserId.isNotEmpty) {
        followingResponse = await Supabase.instance.client
            .from('follows')
            .select('following_id')
            .eq('follower_id', currentUserId);
      }

      setState(() {
        _users = List<Map<String, dynamic>>.from(usersResponse);
        _filteredUsers = _users;
        _followingIds = Set<String>.from(
          followingResponse.map((f) => f['following_id'] as String),
        );
        _isLoading = false;
      });

      print('✅ Loaded ${_users.length} users');
    } catch (e) {
      print('❌ Error loading users: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final role = (user['role'] ?? '').toLowerCase();
        return name.contains(query) || email.contains(query) || role.contains(query);
      }).toList();
    });
  }

  Future<void> _toggleFollow(String userId, String userName) async {
    try {
      final String? currentUserId = widget.currentUserId ?? Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null || currentUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to follow users')),
        );
        return;
      }

      final isFollowing = _followingIds.contains(userId);

      if (isFollowing) {
        // Unfollow
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', userId);

        setState(() => _followingIds.remove(userId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unfollowed $userName')),
          );
        }
      } else {
        // Follow
        await Supabase.instance.client
            .from('follows')
            .insert({
              'follower_id': currentUserId,
              'following_id': userId,
            });

        setState(() => _followingIds.add(userId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Following $userName!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Users'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No users found'
                              : 'No users match your search',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isFollowing = _followingIds.contains(user['id']);
                          
                          return _buildUserTile(user, isFollowing);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, bool isFollowing) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: const Color(0xFF6366F1),
        backgroundImage: user['avatar_url'] != null
            ? NetworkImage(user['avatar_url'])
            : null,
        child: user['avatar_url'] == null
            ? Text(
                (user['name'] ?? user['email'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user['name'] ?? user['email'] ?? 'Unknown User',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        user['role']?.isNotEmpty == true
            ? user['role']
            : user['description'] ?? user['email'] ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () => _toggleFollow(user['id'], user['name'] ?? 'User'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.white : const Color(0xFF6366F1),
          foregroundColor: isFollowing ? const Color(0xFF6366F1) : Colors.white,
          side: isFollowing
              ? const BorderSide(color: Color(0xFF6366F1))
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(isFollowing ? 'Following' : 'Follow'),
      ),
      onTap: () {
        // Navigate to user's profile
        print('Tapped on user: ${user['id']}');
      },
    );
  }
}
