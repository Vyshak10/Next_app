import 'package:flutter/material.dart';//company.dart

import '../../common_widget/company_post.dart';
import '../../common_widget/home.dart';
import '../../common_widget/profile.dart';
import '../../common_widget/messages.dart';
import '../../common_widget/company_profile.dart';
import '../../common_widget/items_card.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // 👇 Hardcoded userId for demo
  final String userId = '6852';

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildScreenWidget(int index) {
    switch (index) {
      case 0:
        return CompanyHomeScreen(userId: userId);
      case 1:
        return const MessagesPage();
      case 2:
        // Mock company data for demonstration
        final companyData = {
          'name': 'Acme Investments',
          'logo': '',
          'tagline': 'Empowering Startups to Succeed',
          'sector': 'Venture Capital',
          'about': 'Acme Investments is a leading VC firm investing in high-growth startups across technology, health, and fintech sectors.',
          'ticketSize': 'Up to \$2M',
          'preferredSectors': 'Technology, Health, Fintech',
          'stage': 'Seed, Series A',
          'portfolio': ['StartupOne', 'HealthX', 'FinTechPro'],
          'keyPeople': [
            {'name': 'Jane Doe', 'role': 'Managing Partner', 'photo': null},
            {'name': 'John Smith', 'role': 'Investment Director', 'photo': null},
          ],
          'website': 'https://acmeinvestments.com',
          'email': 'contact@acmeinvestments.com',
          'phone': '+1 234 567 890',
          'linkedin': 'linkedin.com/company/acmeinvestments',
        };
        return CompanyProfileScreenWithActions(companyData: companyData);
      default:
        return const Center(child: Text('Invalid tab index'));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildScreenWidget(_selectedIndex),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.chat_bubble_rounded, 'Messages', 1),
              _buildNavItem(Icons.account_circle_rounded, 'Profile', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 24, end: isSelected ? 28 : 24),
                duration: const Duration(milliseconds: 300),
                builder: (context, size, child) {
                  return Icon(
                    icon,
                    color: isSelected ? Colors.blueAccent : Colors.grey[600],
                    size: size,
                  );
                },
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blueAccent : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyProfileScreenWithActions extends StatelessWidget {
  final Map<String, dynamic> companyData;
  const CompanyProfileScreenWithActions({Key? key, required this.companyData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CompanyProfileScreen(companyData: companyData),
        Positioned(
          top: 40,
          right: 20,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.blueAccent, size: 28),
                onPressed: () {
                  // TODO: Implement settings navigation
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings tapped')));
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // TODO: Implement edit profile navigation
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile tapped')));
                },
              ),
            ],
          ),
        ),
        // Video upload button at the bottom
        Positioned(
          bottom: 30,
          right: 20,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.videocam, size: 20),
            label: const Text('Upload 1-min Intro Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // TODO: Implement video upload logic
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video upload tapped')));
            },
          ),
        ),
      ],
    );
  }
}

class CompanyHomeScreen extends StatefulWidget {
  final String userId;
  const CompanyHomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = false;
  List<Map<String, dynamic>> _startups = [];
  bool _isLoadingStartups = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadStartups();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final response = await http.get(Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_posts.php'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['posts'] != null) {
          setState(() {
            _posts = List<Map<String, dynamic>>.from(data['posts']);
          });
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _loadStartups() async {
    setState(() => _isLoadingStartups = true);
    try {
      final response = await http.get(Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_startups.php'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['startups'] != null) {
          setState(() {
            _startups = List<Map<String, dynamic>>.from(data['startups']);
          });
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoadingStartups = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadPosts();
        await _loadStartups();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Startup Recommendations Horizontal Scroll
          Text('Recommended Startups', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: _isLoadingStartups
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _startups.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final s = _startups[i];
                      return GestureDetector(
                        onTap: () {
                          // TODO: Show startup details
                        },
                        child: Container(
                          width: 220,
                          child: CompanyCard(
                            name: s['name'] ?? '',
                            sector: s['sector'] ?? '',
                            logoUrl: s['logo'] ?? '',
                            tags: (s['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          // Posts Section
          Text('Latest Posts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _isLoadingPosts
              ? const Center(child: CircularProgressIndicator())
              : _posts.isEmpty
                  ? const Text('No posts available.')
                  : Column(
                      children: _posts.map((post) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (post['image_urls'] != null && post['image_urls'].isNotEmpty)
                                  SizedBox(
                                    height: 160,
                                    child: PageView.builder(
                                      itemCount: post['image_urls'].length,
                                      itemBuilder: (context, imgIdx) {
                                        return Image.network(
                                          post['image_urls'][imgIdx],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                                        );
                                      },
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(post['title'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(post['description'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: (post['tags'] as List?)?.map((tag) => Chip(label: Text(tag.toString()))).toList() ?? [],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }
}