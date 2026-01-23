import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user profiles and follow relationships in Supabase
class ProfileService {
  final _supabase = Supabase.instance.client;

  /// Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No authenticated user');
        return null;
      }

      print('🔍 Fetching profile for user: $userId');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      print('✅ Profile fetched: ${response['name'] ?? response['email']}');
      
      // Add follower/following counts
      final followerCount = await getFollowerCount(userId);
      final followingCount = await getFollowingCount(userId);
      
      return {
        ...response,
        'followers_count': followerCount,
        'following_count': followingCount,
      };
    } catch (e) {
      print('❌ Error fetching current user profile: $e');
      return null;
    }
  }

  /// Get any user's profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      print('🔍 Fetching profile for user: $userId');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      print('✅ Profile fetched: ${response['name'] ?? response['email']}');
      
      // Add follower/following counts
      final followerCount = await getFollowerCount(userId);
      final followingCount = await getFollowingCount(userId);
      
      // Check if current user follows this profile
      final currentUserId = _supabase.auth.currentUser?.id;
      bool isFollowing = false;
      if (currentUserId != null && currentUserId != userId) {
        isFollowing = await checkIfFollowing(currentUserId, userId);
      }
      
      return {
        ...response,
        'followers_count': followerCount,
        'following_count': followingCount,
        'is_following': isFollowing,
      };
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Update current user's profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('📝 Updating profile for user: $userId');

      await _supabase
          .from('profiles')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('✅ Profile updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  /// Follow a user
  Future<bool> followUser(String userIdToFollow) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      if (currentUserId == userIdToFollow) {
        print('❌ Cannot follow yourself');
        return false;
      }

      print('👥 Following user: $userIdToFollow');

      await _supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': userIdToFollow,
      });

      print('✅ Successfully followed user');
      return true;
    } catch (e) {
      print('❌ Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String userIdToUnfollow) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('👥 Unfollowing user: $userIdToUnfollow');

      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', userIdToUnfollow);

      print('✅ Successfully unfollowed user');
      return true;
    } catch (e) {
      print('❌ Error unfollowing user: $e');
      return false;
    }
  }

  /// Check if current user follows another user
  Future<bool> checkIfFollowing(String followerId, String followingId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error checking follow status: $e');
      return false;
    }
  }

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('following_id', userId);

      return response.count ?? 0;
    } catch (e) {
      print('❌ Error getting follower count: $e');
      return 0;
    }
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('follower_id', userId);

      return response.count ?? 0;
    } catch (e) {
      print('❌ Error getting following count: $e');
      return 0;
    }
  }

  /// Get list of followers for a user
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      print('👥 Fetching followers for user: $userId');

      final response = await _supabase
          .from('follows')
          .select('follower_id, created_at, profiles!follows_follower_id_fkey(*)')
          .eq('following_id', userId)
          .order('created_at', ascending: false);

      print('✅ Found ${response.length} followers');

      return List<Map<String, dynamic>>.from(response.map((follow) {
        final profile = follow['profiles'] as Map<String, dynamic>?;
        return {
          'id': follow['follower_id'],
          'name': profile?['name'] ?? 'Unknown',
          'email': profile?['email'] ?? '',
          'avatar_url': profile?['avatar_url'] ?? '',
          'role': profile?['role'] ?? '',
          'followed_at': follow['created_at'],
        };
      }));
    } catch (e) {
      print('❌ Error fetching followers: $e');
      return [];
    }
  }

  /// Get list of users that a user is following
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      print('👥 Fetching following for user: $userId');

      final response = await _supabase
          .from('follows')
          .select('following_id, created_at, profiles!follows_following_id_fkey(*)')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      print('✅ Found ${response.length} following');

      return List<Map<String, dynamic>>.from(response.map((follow) {
        final profile = follow['profiles'] as Map<String, dynamic>?;
        return {
          'id': follow['following_id'],
          'name': profile?['name'] ?? 'Unknown',
          'email': profile?['email'] ?? '',
          'avatar_url': profile?['avatar_url'] ?? '',
          'role': profile?['role'] ?? '',
          'followed_at': follow['created_at'],
        };
      }));
    } catch (e) {
      print('❌ Error fetching following: $e');
      return [];
    }
  }

  /// Search profiles by name or email
  Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    try {
      if (query.isEmpty) return [];

      print('🔍 Searching profiles for: $query');

      final response = await _supabase
          .from('profiles')
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      print('✅ Found ${response.length} profiles');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error searching profiles: $e');
      return [];
    }
  }
}
