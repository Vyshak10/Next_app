import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing posts using Supabase
class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all posts from Supabase, ordered by creation date (newest first)
  Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            profiles:user_id (
              id,
              name,
              avatar_url,
              user_type
            )
          ''')
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} posts from Supabase');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching posts: $e');
      return [];
    }
  }

  /// Create a new post in Supabase
  Future<Map<String, dynamic>?> createPost({
    required String userId,
    required String title,
    required String description,
    required List<String> imageUrls,
    required List<String> tags,
  }) async {
    try {
      final response = await _supabase.from('posts').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'image_urls': imageUrls,
        'tags': tags,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      print('✅ Post created successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Error creating post: $e');
      return null;
    }
  }

  /// Get posts by a specific user
  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            profiles:user_id (
              id,
              name,
              avatar_url,
              user_type
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching user posts: $e');
      return [];
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _supabase.from('posts').delete().eq('id', postId);
      print('✅ Post deleted: $postId');
      return true;
    } catch (e) {
      print('❌ Error deleting post: $e');
      return false;
    }
  }

  /// Like a post (you'll need to create a 'likes' table in Supabase)
  Future<bool> likePost(String postId, String userId) async {
    try {
      await _supabase.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Post liked: $postId');
      return true;
    } catch (e) {
      print('❌ Error liking post: $e');
      return false;
    }
  }

  /// Unlike a post
  Future<bool> unlikePost(String postId, String userId) async {
    try {
      await _supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      print('✅ Post unliked: $postId');
      return true;
    } catch (e) {
      print('❌ Error unliking post: $e');
      return false;
    }
  }

  /// Add a comment to a post
  Future<bool> addComment({
    required String postId,
    required String userId,
    required String body,
  }) async {
    try {
      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'body': body,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Comment added to post: $postId');
      return true;
    } catch (e) {
      print('❌ Error adding comment: $e');
      return false;
    }
  }

  /// Get comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
            *,
            profiles:user_id (
              id,
              name,
              avatar_url
            )
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching comments: $e');
      return [];
    }
  }
}
