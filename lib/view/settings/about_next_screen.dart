import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutNextScreen extends StatelessWidget {
  const AboutNextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'About NEXT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo and App Name
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.1),
                  Colors.blue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/img/Icon.png',
                    height: 80,
                    width: 80,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'N.E.X.T',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Networking, Entrepreneurship, eXchange, Technology',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Mission Statement
          _buildSectionHeader('Our Mission'),
          _buildInfoCard(
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'NEXT connects startups with established companies, fostering innovation and collaboration. We believe in creating meaningful partnerships that drive growth and success for all.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Features
          _buildSectionHeader('Key Features'),
          _buildInfoCard(
            child: Column(
              children: [
                _buildFeatureTile(
                  Icons.handshake,
                  'Connect & Collaborate',
                  'Build meaningful partnerships',
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  Icons.trending_up,
                  'Grow Your Network',
                  'Expand your professional reach',
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  Icons.lightbulb,
                  'Share Innovation',
                  'Exchange ideas and opportunities',
                ),
                const Divider(height: 1),
                _buildFeatureTile(
                  Icons.analytics,
                  'Track Progress',
                  'Monitor your growth and engagement',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact & Social
          _buildSectionHeader('Connect With Us'),
          _buildInfoCard(
            child: Column(
              children: [
                _buildContactTile(
                  Icons.email,
                  'Email',
                  'support@next-app.com',
                  () => _launchEmail('support@next-app.com'),
                ),
                const Divider(height: 1),
                _buildContactTile(
                  Icons.language,
                  'Website',
                  'www.next-app.com',
                  () => _launchUrl('https://www.next-app.com'),
                ),
                const Divider(height: 1),
                _buildContactTile(
                  Icons.phone,
                  'Phone',
                  '+1 (555) 123-4567',
                  () => _launchPhone('+15551234567'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Legal
          _buildSectionHeader('Legal'),
          _buildInfoCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.blueAccent),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to terms
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.blueAccent),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel, color: Colors.blueAccent),
                  title: const Text('Licenses'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showLicensePage(context: context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Copyright
          Center(
            child: Column(
              children: [
                Text(
                  '© 2024 NEXT. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Made with ❤️ for entrepreneurs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
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

  Widget _buildInfoCard({required Widget child}) {
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

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blueAccent, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildContactTile(IconData icon, String label, String value, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
