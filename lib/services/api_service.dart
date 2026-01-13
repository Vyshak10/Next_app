import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:next_app/config.dart';

class ApiService {
  static const String baseUrl = kBackendBaseUrl;
  
  // Helper method for GET requests
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return _handleResponse(response);
  }

  // Helper method for POST requests
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // Helper method for multipart requests (file uploads)
  Future<Map<String, dynamic>> multipartRequest(
    String endpoint,
    Map<String, String> fields,
    Map<String, List<int>> files,
  ) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));
    
    // Add fields
    request.fields.addAll(fields);

    // Add files
    files.forEach((key, value) {
      request.files.add(http.MultipartFile.fromBytes(key, value));
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Auth methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('Making login request to: $baseUrl/login.php');
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'userType': 'startup', // Default to startup
      }),
    );
    print('Login response status: ${response.statusCode}');
    print('Login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Parsed login data: $data');
      
      if (data['success']) {
        final userId = data['userData']['id']?.toString();
        print('Extracted user ID: $userId');
        
        if (userId == null) {
          print('User ID is null in response');
          return {
            'success': false,
            'message': 'Invalid user data received',
          };
        }
        
        return {
          'success': true,
          'user_id': userId,
          'userData': data['userData'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
      };
    } else {
      print('Login failed with status: ${response.statusCode}');
      throw Exception('Login failed: ${response.body}');
    }
  }

  // Profile related methods
  Future<Map<String, dynamic>> getProfile(String userId) async {
    return await get('get_profile.php?user_id=$userId');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    return await post('update_profile.php', profileData);
  }

  Future<Map<String, dynamic>> uploadProfilePicture(String userId, List<int> imageBytes) async {
    return await multipartRequest(
      'upload_profile_picture.php',
      {'user_id': userId},
      {'profile_picture': imageBytes},
    );
  }

  // Posts related methods
  Future<List<dynamic>> getPosts() async {
    final response = await get('get_posts.php');
    return response['posts'] ?? [];
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    return await post('create_post.php', postData);
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    return await post('like_post.php', {'post_id': postId});
  }

  Future<Map<String, dynamic>> addComment(String postId, String comment) async {
    return await post('add_comment.php', {
      'post_id': postId,
      'comment': comment,
    });
  }

  // Startup discovery methods
  Future<List<dynamic>> getStartups() async {
    final response = await get('get_startups.php');
    return response['startups'] ?? [];
  }

  Future<Map<String, dynamic>> connectWithStartup(String startupId) async {
    return await post('connect_startup.php', {'startup_id': startupId});
  }

  // Notifications methods
  Future<List<dynamic>> getNotifications() async {
    final response = await get('get_notifications.php');
    return response['notifications'] ?? [];
  }

  Future<Map<String, dynamic>> toggleNotifications(bool enabled) async {
    return await post('toggle_notifications.php', {'enabled': enabled});
  }

  // Messaging methods
  Future<List<dynamic>> getMessages(String otherUserId) async {
    final response = await get('get_messages.php?other_user_id=$otherUserId');
    return response['messages'] ?? [];
  }

  Future<Map<String, dynamic>> sendMessage(String receiverId, String message) async {
    return await post('send_message.php', {
      'receiver_id': receiverId,
      'message': message,
    });
  }

  // Meetings methods
  Future<Map<String, dynamic>> createMeeting(Map<String, dynamic> meetingData) async {
    return await post('create_meeting.php', meetingData);
  }

  Future<List<dynamic>> getUpcomingMeetings() async {
    final response = await get('get_meetings.php');
    return response['meetings'] ?? [];
  }

  // Search users by username and type
  Future<List<Map<String, dynamic>>> searchUser(String username, String type) async {
    final response = await get('search_user.php?username=$username&type=$type');
    if (response['success'] == true && response['results'] != null) {
      return List<Map<String, dynamic>>.from(response['results']);
    }
    return [];
  }
} 