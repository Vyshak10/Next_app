import 'package:flutter/material.dart';
import 'package:next_app/services/auth_service.dart';

class SignupView extends StatefulWidget {
  const SignupView({Key? key}) : super(key: key);

  @override
  _SignupViewState createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedUserType = 'seeker';
  bool _isLoading = false;
  String? _errorMessage;

  // Additional fields for different user types
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();
  final _startupNameController = TextEditingController();
  final _stageController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _skillsController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _industryController.dispose();
    _startupNameController.dispose();
    _stageController.dispose();
    _fullNameController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final result = await authService.signUp(
  email: _emailController.text,
  password: _passwordController.text,
  userType: _selectedUserType,
  name: _selectedUserType == 'seeker'
      ? _fullNameController.text
      : 'N/A',
  companyName: _selectedUserType == 'company'
      ? _companyNameController.text
      : null,
  industry: _selectedUserType == 'company'
      ? _industryController.text
      : null,
  startupName: _selectedUserType == 'startup'
      ? _startupNameController.text
      : null,
  stage: _selectedUserType == 'startup'
      ? _stageController.text
      : null,
  skills: _selectedUserType == 'seeker'
      ? _skillsController.text
      : null,
);


      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildUserTypeFields() {
    switch (_selectedUserType) {
      case 'company':
        return Column(
          children: [
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _industryController,
              decoration: const InputDecoration(
                labelText: 'Industry',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter industry';
                }
                return null;
              },
            ),
          ],
        );
      case 'startup':
        return Column(
          children: [
            TextFormField(
              controller: _startupNameController,
              decoration: const InputDecoration(
                labelText: 'Startup Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.rocket_launch),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter startup name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stageController,
              decoration: const InputDecoration(
                labelText: 'Stage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter startup stage';
                }
                return null;
              },
            ),
          ],
        );
      case 'seeker':
        return Column(
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skillsController,
              decoration: const InputDecoration(
                labelText: 'Skills',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.psychology),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your skills';
                }
                return null;
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: const InputDecoration(
                      labelText: 'User Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'seeker',
                        child: Text('Job Seeker'),
                      ),
                      DropdownMenuItem(
                        value: 'company',
                        child: Text('Company'),
                      ),
                      DropdownMenuItem(
                        value: 'startup',
                        child: Text('Startup'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUserType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildUserTypeFields(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 