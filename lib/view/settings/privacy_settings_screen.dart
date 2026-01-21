import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final storage = const FlutterSecureStorage();
  
  bool _profileVisibility = true;
  bool _showEmail = false;
  bool _showPhone = false;
  bool _allowMessages = true;
  bool _allowConnectionRequests = true;
  String _whoCanSeeProfile = 'Everyone';
  String _whoCanContact = 'Connections';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Privacy Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.1),
                  Colors.blue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.blueAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control Your Privacy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage who can see and contact you',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Profile Visibility Section
          _buildSectionHeader('Profile Visibility'),
          _buildSettingsCard(
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Make Profile Public'),
                  subtitle: const Text('Allow others to find and view your profile'),
                  value: _profileVisibility,
                  activeColor: Colors.blueAccent,
                  onChanged: (value) {
                    setState(() => _profileVisibility = value);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Who can see your profile'),
                  subtitle: Text(_whoCanSeeProfile),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showProfileVisibilityDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact Information Section
          _buildSectionHeader('Contact Information'),
          _buildSettingsCard(
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Show Email Address'),
                  subtitle: const Text('Display your email on your profile'),
                  value: _showEmail,
                  activeColor: Colors.blueAccent,
                  onChanged: (value) {
                    setState(() => _showEmail = value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Show Phone Number'),
                  subtitle: const Text('Display your phone on your profile'),
                  value: _showPhone,
                  activeColor: Colors.blueAccent,
                  onChanged: (value) {
                    setState(() => _showPhone = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Communication Preferences
          _buildSectionHeader('Communication'),
          _buildSettingsCard(
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Allow Direct Messages'),
                  subtitle: const Text('Let others send you messages'),
                  value: _allowMessages,
                  activeColor: Colors.blueAccent,
                  onChanged: (value) {
                    setState(() => _allowMessages = value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Allow Connection Requests'),
                  subtitle: const Text('Receive requests to connect'),
                  value: _allowConnectionRequests,
                  activeColor: Colors.blueAccent,
                  onChanged: (value) {
                    setState(() => _allowConnectionRequests = value);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Who can contact you'),
                  subtitle: Text(_whoCanContact),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showContactPermissionDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data & Privacy
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsCard(
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.blueAccent),
                  title: const Text('Download Your Data'),
                  subtitle: const Text('Get a copy of your information'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showSnackBar('Data download request submitted');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.orange),
                  title: const Text('Blocked Users'),
                  subtitle: const Text('Manage blocked accounts'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to blocked users screen
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save Button
          ElevatedButton(
            onPressed: () {
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Privacy Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  void _showProfileVisibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Who can see your profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Everyone'),
              value: 'Everyone',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() => _whoCanSeeProfile = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Connections Only'),
              value: 'Connections Only',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() => _whoCanSeeProfile = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Nobody'),
              value: 'Nobody',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() => _whoCanSeeProfile = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showContactPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Who can contact you'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Everyone'),
              value: 'Everyone',
              groupValue: _whoCanContact,
              onChanged: (value) {
                setState(() => _whoCanContact = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Connections'),
              value: 'Connections',
              groupValue: _whoCanContact,
              onChanged: (value) {
                setState(() => _whoCanContact = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Nobody'),
              value: 'Nobody',
              groupValue: _whoCanContact,
              onChanged: (value) {
                setState(() => _whoCanContact = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    _showSnackBar('Privacy settings saved successfully');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
