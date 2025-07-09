import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../login/user_type.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = false;
  final storage = const FlutterSecureStorage();
  final String baseUrl = "https://indianrupeeservices.in/NEXT/backend/api"; // Change this

  String? _userId;
  String? _authToken;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final token = await storage.read(key: 'auth_token');
    final userId = await storage.read(key: 'user_id');
    final userType = await storage.read(key: 'user_type');

    if (token != null && userId != null) {
      setState(() {
        _authToken = token;
        _userId = userId;
        _userType = userType;
      });
      _loadNotificationSettings();
    }
  }

  Future<void> _loadNotificationSettings() async {
    if (_userId == null || _authToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notification-status?user_id=$_userId'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _notificationsEnabled = data['notify_enabled'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_userId == null || _authToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-notification'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': _userId, 'notify_enabled': value}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notificationsEnabled = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Notifications enabled' : 'Notifications disabled',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update notification settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && _userId != null && _authToken != null) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/delete-account'),
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'user_id': _userId}),
        );

        if (response.statusCode == 200) {
          await storage.deleteAll();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserType()),
            );
          }
        } else {
          throw Exception('Failed with status ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await storage.deleteAll();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserType()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Appearance Section
          sectionHeader('Appearance'),
          settingsCard(
            SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() => _darkModeEnabled = value);
                // TODO: Implement dark mode switch logic
              },
            ),
          ),

          const SizedBox(height: 24),

          // Notifications
          sectionHeader('Notifications'),
          settingsCard(
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive updates about your profile and connections'),
              secondary: const Icon(Icons.notifications_none_outlined),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),

          const SizedBox(height: 24),

          // Company-specific options
          if (_userType == 'company' || _userType == 'Established Company') ...[
            sectionHeader('Company Settings'),
            settingsCard(
              Column(
                children: [
                  ListTile(
                    title: const Text('Edit Company Profile'),
                    leading: const Icon(Icons.business),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      // Navigate to company profile edit screen
                      Navigator.pushNamed(context, '/edit-company-profile');
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Manage Team Members'),
                    leading: const Icon(Icons.group),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.pushNamed(context, '/manage-team');
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Upload/Change Company Logo'),
                    leading: const Icon(Icons.image),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.pushNamed(context, '/upload-company-logo');
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Manage Achievements'),
                    leading: const Icon(Icons.emoji_events),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.pushNamed(context, '/manage-achievements');
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Request Company Verification'),
                    leading: const Icon(Icons.verified),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Request Verification'),
                          content: const Text('Your request for company verification will be reviewed by our team.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Company Analytics'),
                    leading: const Icon(Icons.analytics),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.pushNamed(context, '/company-analytics');
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Manage Portfolio'),
                    leading: const Icon(Icons.work),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.pushNamed(context, '/manage-portfolio');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Privacy & Security
          sectionHeader('Privacy & Security'),
          settingsCard(
            Column(
              children: [
                ListTile(
                  title: const Text('Privacy Settings'),
                  leading: const Icon(Icons.lock_outline),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    print('Privacy Settings tapped');
                  },
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('Location Services'),
                  leading: const Icon(Icons.location_on_outlined),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    print('Location Services tapped');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About
          sectionHeader('About'),
          settingsCard(
            Column(
              children: [
                ListTile(
                  title: const Text('Help & Support'),
                  leading: const Icon(Icons.help_outline),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                    );
                  },
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('About NEXT'),
                  leading: const Icon(Icons.info_outline),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    print('About NEXT tapped');
                  },
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('App Version'),
                  leading: const Icon(Icons.smartphone),
                  trailing: Text('1.0.0', style: TextStyle(color: Colors.grey[600])),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Danger Zone
          sectionHeader('Danger Zone', color: Colors.red[700]),
          settingsCard(
            ListTile(
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account and all data'),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: _deleteAccount,
            ),
          ),

          const SizedBox(height: 32),

          // Sign Out Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _signOut,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout, size: 20),
                SizedBox(width: 8),
                Text('Sign Out', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.grey[700],
        ),
      ),
    );
  }

  Widget settingsCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
