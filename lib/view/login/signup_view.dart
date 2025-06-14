import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:next_app/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController industryController = TextEditingController();
  final TextEditingController startupNameController = TextEditingController();
  final TextEditingController stageController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();

  String userType = 'Unknown';
  bool isLoading = false;
  bool acceptTerms = false;
  bool _obscurePassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    userType = args?['userType'] ?? 'Unknown';
  }

  Future<void> _signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password');
      return;
    }

    if (userType == 'Established Company' && companyNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter company name');
      return;
    }

    if (userType == 'Startup' && startupNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter startup name');
      return;
    }

    if (userType == 'Job Seeker' && fullNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter full name');
      return;
    }

    if (!acceptTerms) {
      _showSnackBar('Please accept the terms and conditions');
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = AuthService();
      final result = await authService.signUp(
        email: email,
        password: password,
        userType: userType,
        companyName: companyNameController.text.trim(),
        industry: industryController.text.trim(),
        startupName: startupNameController.text.trim(),
        stage: stageController.text.trim(),
        fullName: fullNameController.text.trim(),
        skills: skillsController.text.trim(),
      );

      if (result['success'] == true) {
        _showSnackBar('Signup successful! Please check your email for verification.');
        Navigator.pushReplacementNamed(context, '/login', arguments: {'userType': userType});
      } else {
        _showSnackBar(result['message'] ?? 'Signup failed');
      }
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
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
                'Create Account',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Sign up as a $userType', style: const TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 30),
              _buildSignupForm(userType),
              const SizedBox(height: 30),
              Row(
                children: [
                  Checkbox(
                    value: acceptTerms,
                    onChanged: (value) => setState(() => acceptTerms = value ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/terms-and-conditions'),
                      child: RichText(
                        text: const TextSpan(
                          text: 'I accept the ',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                          children: [
                            TextSpan(
                              text: 'terms and conditions',
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: acceptTerms && !isLoading ? _signUp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login', arguments: {'userType': userType});
                  },
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm(String userType) {
    switch (userType) {
      case 'Established Company':
        return _establishedCompanyForm();
      case 'Startup':
        return _startupForm();
      case 'Job Seeker':
        return _jobSeekerForm();
      default:
        return const Center(child: Text('Invalid user type.'));
    }
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      obscureText: _obscurePassword,
    );
  }

  Widget _establishedCompanyForm() {
    return Column(
      children: [
        TextField(
          controller: companyNameController,
          decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: industryController,
          decoration: const InputDecoration(labelText: 'Industry', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _startupForm() {
    return Column(
      children: [
        TextField(
          controller: startupNameController,
          decoration: const InputDecoration(labelText: 'Startup Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: stageController,
          decoration: const InputDecoration(labelText: 'Stage of Startup', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _jobSeekerForm() {
    return Column(
      children: [
        TextField(
          controller: fullNameController,
          decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: skillsController,
          decoration: const InputDecoration(labelText: 'Skills', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    companyNameController.dispose();
    industryController.dispose();
    startupNameController.dispose();
    stageController.dispose();
    fullNameController.dispose();
    skillsController.dispose();
    super.dispose();
  }
}
