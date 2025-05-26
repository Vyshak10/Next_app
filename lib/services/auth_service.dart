import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // SignUp: includes saving userType to 'profiles' table
  Future<String?> signUp(String email, String password, String userType) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Check if profile already exists
        final existingProfile = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', user.id)
            .limit(1);

        if (existingProfile.isEmpty) {
          // Save userType in the 'profiles' table only if it doesn't exist
          await _supabase.from('profiles').insert({
            'id': user.id,
            'user_type': userType,
          });
        }
        return null; // success
      } else {
        return 'Signup failed. Please try again.';
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // SignIn: returns error and userType as a record
  Future<(String? error, String? userType)> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Use select().limit(1) instead of .single() to avoid PGRST116 error
        final profileResponse = await _supabase
            .from('profiles')
            .select('user_type')
            .eq('id', user.id)
            .limit(1);

        if (profileResponse.isNotEmpty) {
          final userType = profileResponse[0]['user_type'] as String?;
          return (null, userType);
        } else {
          // Profile doesn't exist, create one with default user type
          return ('Profile not found. Please contact support.', null);
        }
      } else {
        return ('Login failed. Please try again.', null);
      }
    } on AuthException catch (e) {
      return (e.message, null);
    } catch (e) {
      return ('Unexpected error: $e', null);
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
}