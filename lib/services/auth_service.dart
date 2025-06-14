import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "https://indianrupeeservices.in/NEXT/backend";

  /// SIGN UP
  Future<String?> signUp(String email, String password, String userType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'userType': userType,
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return null; // success
    } else {
      return data['message'] ?? 'Signup failed'; // ✅ fixed key
    }
  }

  /// LOGIN
  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      // You can store userType or userId from response if needed
      return null; // login successful
    } else {
      return data['message'] ?? 'Login failed'; // ✅ fixed key
    }
  }
}
