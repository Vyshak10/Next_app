


import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:next_app/view/login/login_view.dart';
import '../view/homepage/home.dart';
=======
import 'package:next_app/view/homepage/company.dart';
import 'package:next_app/view/homepage/seeker.dart';
import 'package:next_app/view/login/login_view.dart';
import '../view/homepage/startUp.dart';
>>>>>>> 162a41c (implented post)
import '../view/login/signup_view.dart';



class AppRoutes {
  static const String signup = '/signup';
  static const String login= '/login';
<<<<<<< HEAD
  static const String home = '/home';

=======
  static const String startUp = '/startUp';
  static const String Company = '/Company';
  static const String seeker = '/Seeker';
>>>>>>> 162a41c (implented post)

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      signup: (context) => const SignUpPage(),
      login: (context) => const LoginView(),
<<<<<<< HEAD
      home: (context) => const HomePage(),
=======
      startUp: (context) => const Startup(),
      Company: (context) => const CompanyScreen(),
      seeker: (context) => const SeekerPage()
>>>>>>> 162a41c (implented post)
    };
  }
}