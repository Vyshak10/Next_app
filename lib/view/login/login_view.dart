import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String userType = 'Unknown';
  bool _obscurePassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    userType = args?['userType'] ?? 'Unknown';
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password');
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('https://indianrupeeservices.in/NEXT/backend/login.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'userType': userType,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        _showSnackBar('Login successful!');
        _navigateToUserScreen(userType);
      } else {
        _showSnackBar('Login failed: ${result['error'] ?? 'Unknown error'}');
      }
    } else {
      _showSnackBar('Server error: ${response.statusCode}');
    }
  }

  void _navigateToUserScreen(String userType) {
    switch (userType) {
      case 'Job Seeker':
        Navigator.pushReplacementNamed(context, '/Seeker');
        break;
      case 'Startup':
        Navigator.pushReplacementNamed(context, '/startUp');
        break;
      case 'Established Company':
        Navigator.pushReplacementNamed(context, '/Company');
        break;
      default:
        _showSnackBar('Unknown user type: $userType');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Login as a $userType',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text(
                    'Login',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup', arguments: {'userType': userType});
                  },
                  child: const Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
