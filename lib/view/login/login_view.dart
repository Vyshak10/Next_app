

import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String userType = args?['userType'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                'Log in to your Account',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),

              SizedBox(height: 20),

              TextField(
                decoration: InputDecoration(labelText: 'Email'),
              ),

              SizedBox(height: 20),

              TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: Icon(Icons.remove_red_eye),
                ),
                obscureText: true,
              ),

              SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (userType == 'Job Seeker') {
                      Navigator.pushNamed(context, '/Seeker');
                    } else if (userType == 'Startup') {
                      Navigator.pushNamed(context, '/startUp');
                    } else if (userType == 'Established Company') {
                      Navigator.pushNamed(context, '/Company');
                    } else {
                      // fallback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid user type')),
                      );
                    }
                  },

                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
