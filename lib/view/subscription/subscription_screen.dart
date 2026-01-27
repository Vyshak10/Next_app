import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isAnnual = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Upgrade Plan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Unlock the full power of N.E.X.T',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the plan that suits your ambition.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_buildToggleOption('Monthly', !isAnnual)],
              ),
            ),
            const SizedBox(height: 32),

            // Plan Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanCard(
                    title: 'Free',
                    price: '0',
                    subtitle: 'Explore the startup ecosystem',
                    buttonText: 'Current Plan',
                    isCurrent: true,
                    features: [
                      'Browse limited startup and company profiles',
                      'Create a basic organization profile',
                      'View public funding goals',
                      'Read-only access to messages and updates',
                      'Basic dashboard overview',
                    ],
                  ),
                  const SizedBox(width: 16),
                  _buildPlanCard(
                    title: 'Go',
                    price: '29',
                    subtitle: 'Connect and collaborate effectively',
                    buttonText: 'Upgrade to Go',
                    features: [
                      'Create full startup or company profiles',
                      'Discover startups by sector and funding stage',
                      'Send and receive direct messages',
                      'Request and schedule pitch meetings',
                      'Share and view funding requirements',
                      'Basic portfolio tracking',
                    ],
                  ),
                  const SizedBox(width: 16),
                  _buildPlanCard(
                    title: 'Plus',
                    price: '99',
                    subtitle: 'Grow with analytics and insights',
                    buttonText: 'Upgrade to Plus',
                    isPopular: true,
                    features: [
                      'Advanced startup discovery and filters',
                      'Secure pairing codes with partners',
                      'Growth KPIs with monthly and yearly insights',
                      'Portfolio management dashboard',
                      'Priority messaging access',
                      'Funding activity timelines',
                      'Access to curated business resources',
                    ],
                  ),
                  const SizedBox(width: 16),
                  _buildPlanCard(
                    title: 'Pro',
                    price: '299',
                    subtitle: 'Scale partnerships and investments',
                    buttonText: 'Upgrade to Pro',
                    features: [
                      'Unlimited startup and company interactions',
                      'Advanced analytics and performance reports',
                      'Enterprise-level portfolio insights',
                      'Priority meeting scheduling',
                      'Early access to new platform features',
                      'Custom integrations and automation support',
                      'Enhanced brand visibility on the platform',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Prices in USD per month. Cancel anytime.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => isAnnual = !isAnnual),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String subtitle,
    required String buttonText,
    required List<String> features,
    bool isCurrent = false,
    bool isPopular = false,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPopular ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? Colors.transparent : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          if (!isPopular)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          else
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isPopular ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$$price',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isPopular ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                ' /month',
                style: TextStyle(
                  color: isPopular ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isPopular ? Colors.white70 : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrent
                        ? Colors.grey[200]
                        : (isPopular ? Colors.white : Colors.black),
                foregroundColor:
                    isCurrent
                        ? Colors.black54
                        : (isPopular ? Colors.black : Colors.white),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color:
                        isPopular ? Colors.blueAccent.shade100 : Colors.black54,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: isPopular ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
