import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              '1. Eligibility',
              'By using N.E.X.T., you must be at least 18 years old and have the legal capacity to enter into binding contracts. You must provide accurate and complete information when creating your account.',
            ),
            _buildSection(
              '2. Account Responsibilities',
              'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.',
            ),
            _buildSection(
              '3. Use Restrictions',
              'You agree not to:\n'
              '• Use the service for any illegal purpose\n'
              '• Attempt to gain unauthorized access\n'
              '• Use automated systems or bots\n'
              '• Scrape or collect user data\n'
              '• Interfere with the proper functioning of the service',
            ),
            _buildSection(
              '4. Service Availability',
              'We strive to maintain high availability but do not guarantee uninterrupted service. We reserve the right to modify, suspend, or discontinue any part of the service at any time.',
            ),
            _buildSection(
              '5. Intellectual Property',
              'All content, features, and functionality of N.E.X.T. are owned by us and are protected by international copyright, trademark, and other intellectual property laws.',
            ),
            _buildSection(
              '6. User-Generated Content',
              'You retain ownership of your content but grant us a license to use, modify, and display it in connection with the service. We reserve the right to remove any content that violates our policies.',
            ),
            _buildSection(
              '7. Matching Disclaimer',
              'N.E.X.T. provides a platform for connecting users but does not guarantee job placements, funding, or successful matches. All interactions and agreements between users are at their own discretion.',
            ),
            _buildSection(
              '8. Termination',
              'We reserve the right to terminate or suspend your account at any time for violations of these terms. You may terminate your account at any time by following the account deletion process.',
            ),
            _buildSection(
              '9. Privacy Policy',
              'Your use of N.E.X.T. is also governed by our Privacy Policy, which explains how we collect, use, and protect your personal information.',
            ),
            _buildSection(
              '10. Data Collection',
              'We collect and process:\n'
              '• Profile information\n'
              '• Usage data\n'
              '• Communication data\n'
              '• Device information',
            ),
            _buildSection(
              '11. Data Protection',
              'We implement appropriate security measures to protect your data. We use cpanel for secure data storage and processing.',
            ),
            _buildSection(
              '12. User Rights',
              'You have the right to:\n'
              '• Access your personal data\n'
              '• Request data deletion\n'
              '• Export your data\n'
              '• Opt-out of marketing communications',
            ),
            _buildSection(
              '13. Cookie Policy',
              'We use cookies and similar technologies to:\n'
              '• Maintain your session\n'
              '• Analyze service usage\n'
              '• Improve user experience',
            ),
            _buildSection(
              '14. Community Guidelines',
              'Users must:\n'
              '• Treat others with respect\n'
              '• Not engage in harassment\n'
              '• Not discriminate\n'
              '• Report violations',
            ),
            _buildSection(
              '15. Communication Consent',
              'By using N.E.X.T., you consent to receive:\n'
              '• Service notifications\n'
              '• Account updates\n'
              '• Marketing communications (optional)',
            ),
            _buildSection(
              '16. Governing Law',
              'These terms are governed by the laws of India. Any disputes shall be resolved through arbitration in accordance with the Arbitration and Conciliation Act, 1996.',
            ),
            const SizedBox(height: 24),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 