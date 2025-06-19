import 'package:flutter/material.dart';
import 'package:next_app/view/homepage/company.dart';
import 'package:next_app/view/homepage/seeker.dart';
import 'package:next_app/view/login/login_view.dart';
import 'package:next_app/view/legal/terms_and_conditions.dart';
import 'package:next_app/view/homepage/startUp.dart';
import 'package:next_app/view/login/signup_view.dart';
import 'package:next_app/view/on_boarding/started_view.dart';
import 'package:next_app/view/on_boarding/onboardingpages.dart';
import 'package:next_app/view/login/user_type.dart';
import 'package:next_app/common_widget/profile.dart'; // ✅ Profile Screen import

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String userType = '/user-type';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String startUp = '/startUp';
  static const String company = '/company';
  static const String seeker = '/seeker';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const StartedView(),
      onboarding: (context) => const OnboardingPages(),
      userType: (context) => const UserType(),
      signup: (context) => const SignUpPage(),
      login: (context) => const LoginView(),
      startUp: (context) => const Startup(),
      company: (context) => const CompanyScreen(),
      seeker: (context) => const SeekerPage(),
      termsAndConditions: (context) => const TermsAndConditions(),

      /// ✅ Profile route (with arguments handling and fallback)
      profile: (context) {
        final args = ModalRoute.of(context)!.settings.arguments;

        if (args is Map<String, dynamic> &&
            args.containsKey('userId') &&
            args.containsKey('onBackTap')) {
          return ProfileScreen(
            userId: args['userId'],
            onBackTap: args['onBackTap'],
          );
        } else {
          return const Scaffold(
            body: Center(
              child: Text(
                'Error: Invalid arguments for ProfileScreen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }
      },
    };
  }
}
