import 'package:flutter/material.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    userType = args?['userType'] ?? 'Unknown';
  }

  void _signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    // Basic validation for additional fields
    if (userType == 'Established Company' && companyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter company name')),
      );
      return;
    }

    if (userType == 'Startup' && startupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter startup name')),
      );
      return;
    }

    if (userType == 'Job Seeker' && fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter full name')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await AuthService().signUp(email, password, userType);

    setState(() {
      isLoading = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful! Please login.')),
      );
      Navigator.pushReplacementNamed(context, '/login', arguments: {'userType': userType});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $result')),
      );
    }
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
              Text(
                'Sign up as a $userType',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              _buildSignupForm(userType),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _signUp,
                  child: isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
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

  Widget _establishedCompanyForm() {
    return Column(
      children: [
        TextField(
          controller: companyNameController,
          decoration: const InputDecoration(labelText: 'Company Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: industryController,
          decoration: const InputDecoration(labelText: 'Industry'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
      ],
    );
  }

  Widget _startupForm() {
    return Column(
      children: [
        TextField(
          controller: startupNameController,
          decoration: const InputDecoration(labelText: 'Startup Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: stageController,
          decoration: const InputDecoration(labelText: 'Stage of Startup'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
      ],
    );
  }

  Widget _jobSeekerForm() {
    return Column(
      children: [
        TextField(
          controller: fullNameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: skillsController,
          decoration: const InputDecoration(labelText: 'Skills'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
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