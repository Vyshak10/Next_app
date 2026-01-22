import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> submitVerificationRequest({
    required String requesterId,
    required String teamMemberName,
    required String teamMemberRole,
    required String linkedinUrl,
  }) async {
    try {
      await _supabase.from('verification_requests').insert({
        'requester_id': requesterId,
        'team_member_name': teamMemberName,
        'team_member_role': teamMemberRole,
        'linkedin_url': linkedinUrl,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('Error submitting verification request: $e');
      return false;
    }
  }
}
