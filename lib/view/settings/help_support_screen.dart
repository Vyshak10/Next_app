import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showDocumentation(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Contact Support'),
                  subtitle: const Text('Get help from our support team'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _launchURL('mailto:karthikasuresh.v2@gmail.com'),
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Chat with our support team'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    // TODO: Implement live chat functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Live chat coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAQs Section
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
            child: Column(
              children: [
                _buildFAQItem(
                  'How do I update my profile?',
                  'You can update your profile by going to the Profile tab and tapping the edit button next to the section you want to modify.',
                ),
                _buildFAQItem(
                  'How do I connect with other users?',
                  'You can connect with other users by visiting their profiles and tapping the "Connect" button. They will receive a connection request that they can accept or decline.',
                ),
                _buildFAQItem(
                  'How do I delete my account?',
                  'You can delete your account by going to Settings > Danger Zone > Delete Account. Please note that this action cannot be undone.',
                ),
                _buildFAQItem(
                  'How do I report inappropriate content?',
                  'You can report inappropriate content by tapping the three dots menu on any post or profile and selecting "Report". Our team will review your report within 24 hours.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Documentation Section
          Text(
            'Documentation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: const Text('User Guide'),
                  subtitle: const Text('Learn how to use NEXT'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _showDocumentation(
                    context,
                    'User Guide',
                    '''Welcome to NEXT - Your Professional Networking Platform

Getting Started:
1. Create your profile
2. Add your professional information
3. Connect with other professionals
4. Share your updates and achievements

Profile Management:
- Update your profile information
- Add your professional experience
- Upload your pitch video
- Manage your connections

Networking Features:
- Connect with other professionals
- Send and receive messages
- Share updates and achievements
- Participate in discussions

Privacy & Security:
- Control your profile visibility
- Manage connection requests
- Report inappropriate content
- Secure your account

For more detailed information, please contact our support team.''',
                  ),
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Read our privacy policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _showDocumentation(
                    context,
                    'Privacy Policy',
                    '''NEXT Privacy Policy

1. Information We Collect
- Profile information
- Professional details
- Contact information
- Usage data

2. How We Use Your Information
- To provide our services
- To improve user experience
- To communicate with you
- To ensure platform security

3. Information Sharing
- We do not sell your personal information
- We share information only with your consent
- We may share information for legal requirements

4. Your Rights
- Access your data
- Update your information
- Delete your account
- Control your privacy settings

5. Data Security
- We implement security measures
- We regularly update our security protocols
- We monitor for suspicious activities

For any privacy concerns, please contact our support team.''',
                  ),
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  subtitle: const Text('Read our terms of service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _showDocumentation(
                    context,
                    'Terms of Service',
                    '''NEXT Terms of Service

1. Acceptance of Terms
By using NEXT, you agree to these terms and conditions.

2. User Responsibilities
- Provide accurate information
- Maintain account security
- Respect other users
- Follow community guidelines

3. Prohibited Activities
- Harassment or bullying
- Spam or unwanted messages
- False information
- Unauthorized access

4. Content Guidelines
- Professional content only
- No offensive material
- No spam or advertising
- Respect copyright laws

5. Account Termination
We reserve the right to terminate accounts that violate our terms.

For any questions about our terms, please contact our support team.''',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need more help?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our support team is available Monday to Friday, 9 AM to 6 PM IST.',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _launchURL('mailto:karthikasuresh.v2@gmail.com'),
                      child: const Text('karthikasuresh.v2@gmail.com'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 20),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _launchURL('tel:+919061892761'),
                      child: const Text('+91 90618 92761'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
} 