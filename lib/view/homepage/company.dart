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
import '../../common_widget/animated_greeting_gradient_mixin.dart';

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
        return CompanyProfileScreen(companyData: companyData);
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

class _CompanyHomeScreenState extends State<CompanyHomeScreen> with TickerProviderStateMixin, AnimatedGreetingGradientMixin<CompanyHomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = false;
  List<Map<String, dynamic>> _startups = [];
  bool _isLoadingStartups = false;

  String userName = '';
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadStartups();
    _fetchCompanyProfile();
  }

  Future<void> _fetchCompanyProfile() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) return;
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_profile.php?id=${widget.userId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = data['profile'] ?? data['data'];
        if (profile != null) {
          setState(() {
            userName = profile['name'] ?? '';
            avatarUrl = profile['avatar_url'];
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
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

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  // Dummy startup data for horizontal scroll demo
  final List<Map<String, String>> dummyStartups = [
    {
      'logo': 'https://img.icons8.com/color/96/000000/startup.png',
      'name': 'Startup X',
      'sector': 'Fintech',
      'tagline': 'Revolutionizing payments.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/rocket--v1.png',
      'name': 'Rocket Labs',
      'sector': 'Aerospace',
      'tagline': 'Affordable space access.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/idea.png',
      'name': 'Bright Ideas',
      'sector': 'EdTech',
      'tagline': 'Learning made fun.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/robot-2.png',
      'name': 'Botify',
      'sector': 'AI/Robotics',
      'tagline': 'Smarter automation.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/leaf.png',
      'name': 'GreenGen',
      'sector': 'CleanTech',
      'tagline': 'Powering a greener world.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/medical-doctor.png',
      'name': 'MediQuick',
      'sector': 'HealthTech',
      'tagline': 'Instant healthcare access.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/shopping-cart.png',
      'name': 'ShopEase',
      'sector': 'E-Commerce',
      'tagline': 'Shopping made simple.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/bitcoin.png',
      'name': 'CryptoNest',
      'sector': 'Blockchain',
      'tagline': 'Secure crypto solutions.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/online-support.png',
      'name': 'HelpHub',
      'sector': 'Customer Service',
      'tagline': 'Support at your fingertips.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/plant-under-sun.png',
      'name': 'AgroNext',
      'sector': 'AgriTech',
      'tagline': 'Smart farming for all.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/airplane-take-off.png',
      'name': 'FlyHigh',
      'sector': 'Travel',
      'tagline': 'Making travel dreams real.'
    },
    {
      'logo': 'https://img.icons8.com/color/96/000000/paint-palette.png',
      'name': 'Artify',
      'sector': 'Design',
      'tagline': 'Creativity unleashed.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadPosts();
            await _loadStartups();
            await _fetchCompanyProfile();
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Animated greeting gradient (from startup home)
              Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedBuilder(
                  animation: gradientAnimationController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: getGreetingGradient(
                          gradientBeginAnimation.value,
                          gradientEndAnimation.value,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                                ? NetworkImage(avatarUrl!)
                                : const AssetImage('assets/default_avatar.png') as ImageProvider,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName.isNotEmpty ? '${getGreeting()}, $userName' : getGreeting(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                Text(
                                  'Discover innovative startups',
                                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Horizontal scroll of startups
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Startups', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: _isLoadingStartups
                          ? const Center(child: CircularProgressIndicator())
                          : (_startups.isEmpty && dummyStartups.isEmpty)
                              ? Center(child: Text('No startups found.', style: TextStyle(color: Colors.grey[600])))
                              : _startups.isNotEmpty
                                  ? ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _startups.length,
                                      separatorBuilder: (context, i) => const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                        final s = _startups[index];
                                        return GestureDetector(
                                          onTap: () {},
                                          child: Container(
                                            width: 160,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.12),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor: Colors.grey[200],
                                                  backgroundImage: (s['logo'] != null && s['logo'] != '')
                                                      ? NetworkImage(s['logo'])
                                                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  s['name'] ?? 'Startup',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                                if (s['sector'] != null && s['sector'].toString().isNotEmpty)
                                                  Text(
                                                    s['sector'],
                                                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  // Show dummy startups if no real startups
                                  : SizedBox(
                                      height: 110,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: dummyStartups.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                          final startup = dummyStartups[index];
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () {},
                                            child: Container(
                                              width: 130,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                gradient: LinearGradient(
                                                  colors: [Colors.blue.shade50, Colors.white],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.08),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(5),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Center(
                                                      child: CircleAvatar(
                                                        backgroundImage: NetworkImage(startup['logo']!),
                                                        radius: 18,
                                                        backgroundColor: Colors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      startup['name']!,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 10,
                                                        letterSpacing: 0.1,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blueAccent.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        startup['sector']!,
                                                        style: const TextStyle(
                                                          color: Colors.blueAccent,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 8,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      startup['tagline']!,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 8,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      height: 18,
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.blueAccent,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          padding: EdgeInsets.zero,
                                                          elevation: 0,
                                                        ),
                                                        onPressed: () {},
                                                        child: const Text(
                                                          'View',
                                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 9),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Posts Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Latest Posts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              _isLoadingPosts
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                          child: Center(child: Text('No posts available.', style: TextStyle(color: Colors.grey[600]))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _posts.length,
                          itemBuilder: (context, idx) {
                            final post = _posts[idx];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                post['image_urls'][imgIdx],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                                              ),
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
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}