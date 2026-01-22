import 'package:flutter/material.dart';
import 'package:next_app/routes/app_routes.dart';
import 'package:next_app/view/login/reset_password_view.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yewsmbnnizomoedmbzhh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlld3NtYm5uaXpvbW9lZG1iemhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgzMDg5NjQsImV4cCI6MjA4Mzg4NDk2NH0.PjkF6Wjg_k-jcKd4zXN0xr2RE9vE7PqivUgme3lfS60',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinkListener() async {
    _appLinks = AppLinks();

    // Handle initial link if app was opened from a link
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink.toString());
      }
    } catch (e) {
      print('Failed to get initial link: $e');
    }

    // Listen for incoming links while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? link) {
        if (link != null) {
          _handleDeepLink(link.toString());
        }
      },
      onError: (err) {
        print('Failed to receive link: $err');
      },
    );
  }

  void _handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.path.contains('/reset-password')) {
        final token = uri.queryParameters['token'];
        if (token != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordView(token: token),
            ),
          );
        }
      }
    } catch (e) {
      print('Failed to handle deep link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: AppRoutes.getRoutes(),
    );
  }
}
