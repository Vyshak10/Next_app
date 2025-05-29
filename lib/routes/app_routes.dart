import 'package:flutter/material.dart';
import 'package:next_app/view/homepage/company.dart';
import 'package:next_app/view/homepage/seeker.dart';
import 'package:next_app/view/login/login_view.dart';
import '../view/homepage/startUp.dart';
import '../view/login/signup_view.dart';

class AppRoutes {
  static const String signup = '/signup';
  static const String login = '/login';
  static const String startUp = '/startUp';
  static const String Company = '/Company';
  static const String seeker = '/Seeker';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      signup: (context) => const SignUpPage(),
      login: (context) => const LoginView(),
      startUp: (context) => const Startup(),
      Company: (context) => const CompanyScreen(),
      seeker: (context) => const SeekerPage(),
    };
  }
}