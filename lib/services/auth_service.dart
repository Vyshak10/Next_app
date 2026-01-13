import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:next_app/config.dart';

class AuthService {
  final String baseUrl = kBackendBaseUrl;

  /// SIGN UP
 // Update your AuthService.signUp() method to match PHP expectations
Future<Map<String, dynamic>> signUp({
  required String email,
  required String password,
  required String userType,
  required String name,
  required String phone,  // This should be the main name field
  String? companyName,
  String? industry,
  String? startupName,
  String? stage,
  String? fullName,
  String? skills,

}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/signup.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'userType': userType,
        'name': name, // Make sure this matches what PHP expects
        'phone': phone,
        // Add other fields as needed
        'companyName': companyName,
        'industry': industry,
        'startupName': startupName,
        'stage': stage,
        'fullName': fullName,
        'skills': skills,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error: $e'};
  }
}

  /// LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'userType': userType,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Login failed',
          'error': data['error'],
          'userData': data['userData'],
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'error': 'Server error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request_password_reset.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw data['message'] ?? 'Failed to request password reset';
      }
    } catch (e) {
      throw 'Failed to request password reset: ${e.toString()}';
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw data['message'] ?? 'Failed to reset password';
      }
    } catch (e) {
      throw 'Failed to reset password: ${e.toString()}';
    }
  }
}
