import 'package:flutter/material.dart';
import 'messages.dart'; // Import MessagesScreen
import '../view/chat/individual_chat_screen.dart'; // Import IndividualChatScreen

class CompanyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> companyData;
  final String userId;

  const CompanyDetailScreen({
    super.key,
    required this.companyData,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with company logo
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade50,
                      Colors.white,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Company Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: companyData['logo'] != null && companyData['logo'].toString().isNotEmpty
                              ? Image.network(
                            companyData['logo'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderLogo();
                            },
                          )
                              : _buildPlaceholderLogo(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Company Name
                      Text(
                        companyData['name'] ?? 'Company Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      // Company Sector
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          companyData['sector'] ?? 'Technology',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Company Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags Section
                  if (companyData['tags'] != null && (companyData['tags'] as List).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Field',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (companyData['tags'] as List<dynamic>)
                              .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag.toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Pitch Section
                  const Text(
                    'About the Company',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      companyData['description'] ??
                          companyData['pitch'] ??
                          'This innovative company is working on cutting-edge solutions in the ${companyData['sector'] ?? 'technology'} sector. They are focused on creating impactful products that solve real-world problems and drive industry transformation.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Company Image Placeholder
                  const Text(
                    'Company Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Company Image Placeholder',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visual content coming soon',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Additional Company Information
                  if (companyData['founded_year'] != null ||
                      companyData['location'] != null ||
                      companyData['team_size'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Company Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Founded', companyData['founded_year']?.toString()),
                        _buildInfoRow('Location', companyData['location']?.toString()),
                        _buildInfoRow('Team Size', companyData['team_size']?.toString()),
                        _buildInfoRow('Website', companyData['website']?.toString()),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Message Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to MessagesScreen with companyId
                        Navigator.push( // Use push to navigate to the chat screen
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndividualChatScreen(
                              userId: userId, // Pass the current user ID (now a property)
                              partnerId: companyData['id'].toString(), // Pass the company ID as partnerId
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text(
                        'Message Company',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.business,
        size: 40,
        color: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Message ${companyData['name'] ?? 'Company'}'),
          content: const Text(
            'This feature will allow you to send a message directly to the Startup. '
                'Integration with messaging system coming soon!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Messaging feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Send Message'),
            ),
          ],
        );
      },
    );
  }
}