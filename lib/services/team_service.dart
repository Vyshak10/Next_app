import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchTeamMembers(String companyId) async {
    try {
      final response = await _supabase
          .from('team_members')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching team members: $e');
      return [];
    }
  }

  Future<bool> addTeamMember({
    required String companyId,
    required String name,
    required String role,
    File? photoFile,
  }) async {
    try {
      String? photoUrl;
      if (photoFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${photoFile.path.split(Platform.pathSeparator).last}';
        final path = 'team_photos/$fileName';
        await _supabase.storage
            .from('post_images')
            .upload(
              path,
              photoFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
        photoUrl = _supabase.storage.from('post_images').getPublicUrl(path);
      }

      await _supabase.from('team_members').insert({
        'company_id': companyId,
        'name': name,
        'role': role,
        'photo_url': photoUrl,
      });
      return true;
    } catch (e) {
      print('Error adding team member: $e');
      return false;
    }
  }

  Future<bool> updateTeamMemberPhoto(String memberId, File photoFile) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${photoFile.path.split(Platform.pathSeparator).last}';
      final path = 'team_photos/$fileName';
      await _supabase.storage
          .from('post_images')
          .upload(
            path,
            photoFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      final photoUrl = _supabase.storage.from('post_images').getPublicUrl(path);

      await _supabase
          .from('team_members')
          .update({'photo_url': photoUrl})
          .eq('id', memberId);

      return true;
    } catch (e) {
      print('Error updating team member photo: $e');
      return false;
    }
  }
}
