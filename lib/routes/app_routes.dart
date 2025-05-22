


import 'package:flutter/material.dart';
import 'package:next_app/view/login/login_view.dart';
import '../view/homepage/home.dart';
import '../view/login/signup_view.dart';



class AppRoutes {
  static const String signup = '/signup';
  static const String login= '/login';
  static const String home = '/home';


  static Map<String, WidgetBuilder> getRoutes() {
    return {
      signup: (context) => const SignUpPage(),
      login: (context) => const LoginView(),
      home: (context) => const HomePage(),
    };
  }
}