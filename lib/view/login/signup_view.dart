import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:next_app/services/auth_service.dart';
import '../../common_widget/animated_greeting_gradient_mixin.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin, AnimatedGreetingGradientMixin<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController industryController = TextEditingController();
  final TextEditingController startupNameController = TextEditingController();
  final TextEditingController stageController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

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
    final phone = phoneController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter email and password');
      return;
    }
    if (phone.isEmpty) {
      _showSnackBar('Please enter phone number');
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
  name: userType == 'Established Company'
      ? companyNameController.text.trim()
      : userType == 'Startup'
          ? startupNameController.text.trim()
          : fullNameController.text.trim(),
  companyName: companyNameController.text.trim(),
  industry: industryController.text.trim(),
  startupName: startupNameController.text.trim(),
  stage: stageController.text.trim(),
  fullName: fullNameController.text.trim(),
  skills: skillsController.text.trim(),
  // phone: phone,
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
    final isCompany = userType == 'Established Company';
    final accentColor = Colors.deepOrange;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isWide ? 520 : double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (isCompany) ...[
                    Center(
                      child: Column(
                        children: [
                          // Company icon or logo placeholder
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.13),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(Icons.business_center_rounded, color: accentColor, size: 60),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your company account',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start hiring, manage your team, and grow your business!',
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey[400]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          // Company benefits
                          SizedBox(
                            height: 38,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _benefitChip('Post jobs', accentColor),
                                _benefitChip('Team management', accentColor),
                                _benefitChip('Company branding', accentColor),
                                _benefitChip('Advanced analytics', accentColor),
                                _benefitChip('Direct messaging', accentColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Card(
                      color: Colors.white.withOpacity(0.95),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Company Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: accentColor)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: companyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: industryController,
                              decoration: const InputDecoration(
                                labelText: 'Industry',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: stageController,
                              decoration: const InputDecoration(
                                labelText: 'Stage',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Person',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: skillsController,
                              decoration: const InputDecoration(
                                labelText: 'Key Skills',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text('Account Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: accentColor)),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.white.withOpacity(0.95),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 30),
                    const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Sign up as a $userType', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 30),
                    _buildSignupForm(userType),
                  ],
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        boxShadow: acceptTerms && !isLoading
                            ? [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.18),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : [],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: acceptTerms && !isLoading ? _signUp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                            : const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  )
                ],
              ),
            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: companyNameController,
          decoration: const InputDecoration(
            labelText: 'Company Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
        const SizedBox(height: 16),
        TextFormField(
          controller: industryController,
          decoration: const InputDecoration(
            labelText: 'Industry',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: stageController,
          decoration: const InputDecoration(
            labelText: 'Stage',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: fullNameController,
          decoration: const InputDecoration(
            labelText: 'Contact Person',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: skillsController,
          decoration: const InputDecoration(
            labelText: 'Key Skills',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _startupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: startupNameController,
          maxLength: 30,
          decoration: const InputDecoration(
            labelText: 'Startup Name',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter startup name';
            }
            if (value.length > 30) {
              return 'Startup name cannot exceed 30 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
        const SizedBox(height: 16),
        TextFormField(
          controller: stageController,
          decoration: const InputDecoration(
            labelText: 'Stage',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: fullNameController,
          decoration: const InputDecoration(
            labelText: 'Founder Name',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _jobSeekerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
        const SizedBox(height: 16),
        TextFormField(
          controller: skillsController,
          decoration: const InputDecoration(
            labelText: 'Key Skills',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _benefitChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
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
    phoneController.dispose();
    super.dispose();
  }
}
