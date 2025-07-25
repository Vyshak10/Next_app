import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class StartupProfileScreen extends StatefulWidget {
  const StartupProfileScreen({super.key});

  @override
  State<StartupProfileScreen> createState() => _StartupProfileScreenState();
}

class _StartupProfileScreenState extends State<StartupProfileScreen> {
  final storage = FlutterSecureStorage();
  bool isLoading = true;
  Map<String, dynamic>? startupData;
  List teamMembers = [], achievements = [], fundingHistory = [], documents = [], metrics = [], socialLinks = [];

  @override
  void initState() {
    super.initState();
    fetchStartupData();
  }

  Future<void> fetchStartupData() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/api/startup-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          startupData = data['startup'];
          teamMembers = data['team'];
          achievements = data['achievements'];
          fundingHistory = data['funding'];
          documents = data['documents'];
          metrics = data['metrics'];
          socialLinks = data['social_links'];
          isLoading = false;
        });
      } else {
        print('Failed: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Exception: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo and Basic Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Avatar with edit button overlay
              Stack(
                children: [
                  Hero(
                    tag: 'startup_logo',
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: startupData?['logo_url'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                startupData!['logo_url'],
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading startup logo: $error');
                                  return Text(
                                    startupData?['name']?[0].toUpperCase() ?? 'S',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              startupData?['name']?[0].toUpperCase() ?? 'S',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            startupData?['name'] ?? 'Startup Name',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // Navigate to edit profile
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      startupData?['tagline'] ?? 'No tagline',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Industry Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var industry in startupData?['industries'] ?? [])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  industry['name'],
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Add Industry Button
                        InkWell(
                          onTap: () {
                            // Navigate to add industry
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Industry',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Key Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Team Size',
                  teamMembers.length.toString(),
                  Icons.people,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.withOpacity(0.2),
                ),
                _buildStatItem(
                  'Total Funding',
                  '\$${startupData?['total_funding'] ?? 0}',
                  Icons.attach_money,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.withOpacity(0.2),
                ),
                _buildStatItem(
                  'Founded',
                  startupData?['founded_date'] ?? 'N/A',
                  Icons.calendar_today,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Column(
      children: [
        for (var member in teamMembers)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: member['profiles']?['avatar_url'] != null
                    ? NetworkImage(member['profiles']['avatar_url'])
                    : null,
                child: member['profiles']?['avatar_url'] == null
                    ? Text(member['profiles']?['full_name'][0].toUpperCase() ?? '?')
                    : null,
              ),
              title: Text(
                member['profiles']?['full_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member['profiles']?['role'] ?? 'No role specified'),
              trailing: IconButton(
                icon: const Icon(Icons.message, color: Colors.blue),
                onPressed: () {
                  // Navigate to chat with team member
                },
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () {
            // Navigate to add team member
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Team Member'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      children: [
        for (var achievement in achievements)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        achievement['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  achievement['date'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            // Navigate to add achievement
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Achievement'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildFundingSection() {
    return Column(
      children: [
        for (var round in fundingHistory)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_money, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        round['round_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        round['investor_name'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${round['amount']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            // Navigate to add funding round
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Funding Round'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      children: [
        for (var doc in documents)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        doc['type'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blue),
                  onPressed: () {
                    // Download document
                  },
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            // Navigate to add document
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Document'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric['value'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric['label'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialLinksSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var link in socialLinks)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getSocialIcon(link['platform']),
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  link['platform'],
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            // Navigate to add social link
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Social Link'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return FontAwesomeIcons.linkedin;
      case 'twitter':
        return FontAwesomeIcons.twitter;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      default:
        return Icons.link;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120.0, // Adjust as needed
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 1,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(), // Your existing header content
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.black87), // Settings icon
                      onPressed: () {
                        // TODO: Navigate to settings screen
                        print('Settings icon pressed');
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSection('About', Text(startupData?['description'] ?? 'No description available'), icon: Icons.info),
                        _buildSection('Team', _buildTeamSection(), icon: Icons.people),
                        _buildSection('Achievements', _buildAchievementsSection(), icon: Icons.emoji_events),
                        _buildSection('Funding History', _buildFundingSection(), icon: Icons.attach_money),
                        _buildSection('Documents', _buildDocumentsSection(), icon: Icons.description),
                        _buildSection('Metrics', _buildMetricsSection(), icon: Icons.analytics),
                        _buildSection('Social Links', _buildSocialLinksSection(), icon: Icons.link),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 