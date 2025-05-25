import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract the userType argument from ModalRoute
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String userType = args?['userType'] ?? 'Unknown';

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
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Sign up as a $userType',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              _buildSignupForm(userType),

              SizedBox(height: 30,),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/login',
                      arguments: {'userType': userType},
                    );
                  },
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Center(
                child: TextButton(onPressed: (){
                  Navigator.pushNamed(context, '/login');
                },
                    child: Text('Already have an account? Login',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    ),)),
              )

            ],
          ),
        ),
      ),
    );
  }

  // Widget to build form based on user type
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

  // Form for Established Company
  Widget _establishedCompanyForm() {
    return Column(
      children: const [
        TextField(
          decoration: InputDecoration(labelText: 'Company Name'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Industry'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Email'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
      ],
    );
  }

  // Form for Startup
  Widget _startupForm() {
    return Column(
      children: const [
        TextField(
          decoration: InputDecoration(labelText: 'Startup Name'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Stage of Startup'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Email'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
      ],
    );
  }

  // Form for Job Seeker
  Widget _jobSeekerForm() {
    return Column(
      children: const [
        TextField(
          decoration: InputDecoration(labelText: 'Full Name'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Skills'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Email'),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
      ],
    );
  }
}
