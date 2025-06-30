import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common_widget/home.dart';
import '../../common_widget/profile.dart';
import '../../common_widget/messages.dart';
import '../../common_widget/items_card.dart';
import '../../common_widget/company_detail_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common_widget/animated_greeting_gradient_mixin.dart';
import 'package:shimmer/shimmer.dart';
import '../../view/analytics/analytics_dashboard_screen.dart';
import 'dart:math' as math;
import '../../view/profile/company_profile.dart' as company_profile;

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> 
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final String userId = '6852';

  late AnimationController _controller;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fabAnimation;
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);
    _controller.forward();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleFab() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
    if (_isFabOpen) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  Widget _buildScreenWidget(int index) {
    switch (index) {
      case 0:
        return CompanyHomeScreen(userId: userId);
      case 1:
        return const MessagesPage();
      case 2:
        return company_profile.CompanyProfileScreen(userId: userId, onBackTap: () => _onItemTapped(0));
      default:
        return const Center(child: Text('Invalid tab index'));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
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
        bottomNavigationBar: _buildEnhancedBottomNavBar(),
        floatingActionButton: _buildFloatingActionMenu(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildEnhancedBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEnhancedNavItem(Icons.home_rounded, 'Home', 0),
              _buildEnhancedNavItem(Icons.chat_bubble_rounded, 'Messages', 1),
              const SizedBox(width: 60), // Space for FAB
              _buildEnhancedNavItem(Icons.analytics_rounded, 'Analytics', 3),
              _buildEnhancedNavItem(Icons.account_circle_rounded, 'Profile', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => index == 3 ? _navigateToAnalytics() : _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.blueAccent : Colors.grey[600],
                  size: isSelected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blueAccent : Colors.grey[600],
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionMenu() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background overlay
        if (_isFabOpen)
          GestureDetector(
            onTap: _toggleFab,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        // Menu items
        ..._buildFabMenuItems(),
        // Main FAB
        ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton(
            onPressed: _toggleFab,
            backgroundColor: Colors.blueAccent,
            elevation: 8,
            child: AnimatedRotation(
              turns: _isFabOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isFabOpen ? Icons.close : Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFabMenuItems() {
    if (!_isFabOpen) return [];

    final items = [
      {'icon': Icons.campaign, 'label': 'Create Post', 'color': Colors.orange},
      {'icon': Icons.video_call, 'label': 'Schedule Meet', 'color': Colors.green},
      {'icon': Icons.search, 'label': 'Discover', 'color': Colors.purple},
      {'icon': Icons.trending_up, 'label': 'Market Trends', 'color': Colors.red},
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final angle = (index * 45 - 90) * math.pi / 180;
      final radius = 80.0;

      return AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              radius * math.cos(angle) * _fabAnimation.value,
              radius * math.sin(angle) * _fabAnimation.value,
            ),
            child: ScaleTransition(
              scale: _fabAnimation,
              child: _buildFabMenuItem(
                item['icon'] as IconData,
                item['label'] as String,
                item['color'] as Color,
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildFabMenuItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        _toggleFab();
        _handleFabAction(label);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFabAction(String action) {
    HapticFeedback.lightImpact();
    switch (action) {
      case 'Create Post':
        _showCreatePostDialog();
        break;
      case 'Schedule Meet':
        _showScheduleMeetDialog();
        break;
      case 'Discover':
        _showDiscoverModal();
        break;
      case 'Market Trends':
        _showMarketTrendsModal();
        break;
    }
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsDashboardScreen(userId: userId),
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostModal(),
    );
  }

  void _showScheduleMeetDialog() {
    showDialog(
      context: context,
      builder: (context) => const ScheduleMeetDialog(),
    );
  }

  void _showDiscoverModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DiscoverModal(),
    );
  }

  void _showMarketTrendsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MarketTrendsModal(),
    );
  }
}

// Enhanced Company Home Screen with modern UI elements
class CompanyHomeScreen extends StatefulWidget {
  final String userId;
  const CompanyHomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> 
    with TickerProviderStateMixin, AnimatedGreetingGradientMixin<CompanyHomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = false;
  List<Map<String, dynamic>> _startups = [];
  bool _isLoadingStartups = false;
  List<Map<String, dynamic>> _trendingStartups = [];
  List<Map<String, dynamic>> _recentActivities = [];

  String userName = '';
  String? avatarUrl;
  String? companySector;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPosts(),
      _loadStartups(),
      _fetchCompanyProfile(),
      _loadTrendingStartups(),
      _loadRecentActivities(),
    ]);
  }

  Future<void> _loadTrendingStartups() async {
    // Mock trending data - replace with actual API call
    setState(() {
      _trendingStartups = [
        {
          'name': 'TechFlow AI',
          'growth': '+156%',
          'sector': 'AI/ML',
          'funding': '2.3M',
          'logo': 'https://via.placeholder.com/100',
        },
        {
          'name': 'GreenTech Solutions',
          'growth': '+89%',
          'sector': 'CleanTech',
          'funding': '1.8M',
          'logo': 'https://via.placeholder.com/100',
        },
      ];
    });
  }

  Future<void> _loadRecentActivities() async {
    // Mock activity data - replace with actual API call
    setState(() {
      _recentActivities = [
        {
          'company': 'FintechX',
          'type': 'investment',
          'icon': Icons.trending_up,
          'amount': '50,000',
          'time': '2 hours ago',
          'status': '',
        },
        {
          'company': 'Healthify',
          'type': 'meeting',
          'icon': Icons.video_call,
          'amount': '',
          'time': 'Yesterday',
          'status': 'scheduled',
        },
        {
          'company': 'EduSpark',
          'type': 'connection',
          'icon': Icons.person_add_alt_1,
          'amount': '',
          'time': '3 days ago',
          'status': '',
        },
      ];
    });
  }

  Future<void> _fetchCompanyProfile() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) return;
      final response = await http.get(
        Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_profile.php?id=${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body.trim()) as Map<String, dynamic>;
        final profile = data['profile'] ?? data['data'];
        if (profile != null) {
          setState(() {
            userName = profile['name'] ?? profile['full_name'] ?? '';
            avatarUrl = profile['avatar_url'];
            companySector = profile['sector'] ?? profile['industry'];
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
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final uri = Uri.parse('https://indianrupeeservices.in/NEXT/backend/get_startups.php');
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body.trim()) as Map<String, dynamic>? ?? {};
        List<dynamic> startups = [];
        if (data['startups'] != null && data['startups'] is List) {
          startups = data['startups'];
        } else if (data['data'] != null && data['data'] is List) {
          startups = data['data'];
        }
        setState(() {
          _startups = startups.map<Map<String, dynamic>>((s) {
            final m = Map<String, dynamic>.from(s);
            m['logo'] = m['avatar_url'] ?? m['logo'] ?? '';
            m['name'] = m['name'] ?? 'Unknown Startup';
            m['sector'] = m['sector'] ?? '';
            m['tagline'] = m['tagline'] ?? m['bio'] ?? '';
            return m;
          }).toList();
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildEnhancedGreetingCard(),
                  _buildQuickInsightsGrid(),
                  _buildTrendingSection(),
                  _buildRecentActivityCard(),
                  _buildStartupsSection(),
                  _buildPostsSection(),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blueAccent.withOpacity(0.1),
                Colors.white.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/img/Icon.png', height: 32),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Company Dashboard',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Discover & Connect',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildNotificationBell(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_outlined, color: Colors.blueAccent),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedGreetingCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: gradientAnimationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: getGreetingGradient(
                gradientBeginAnimation.value,
                gradientEndAnimation.value,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isNotEmpty ? '${getGreeting()}, $userName' : getGreeting(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to discover innovation?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickInsightsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5,
        children: [
          _buildInsightCard('Active Startups', '${_startups.length}', Icons.business, Colors.blue),
          _buildInsightCard('Total Posts', '${_posts.length}', Icons.article, Colors.green),
          _buildInsightCard('Connections', '47', Icons.people, Colors.orange),
          _buildInsightCard('This Month', '+23%', Icons.trending_up, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    final trendingStartups = (companySector != null && _startups.any((s) => (s['sector'] ?? '').toLowerCase() == companySector!.toLowerCase()))
      ? _startups.where((s) => (s['sector'] ?? '').toLowerCase() == companySector!.toLowerCase()).toList()
      : (_startups..shuffle()).take(3).toList(); // fallback: random startups

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Trending Startups',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (trendingStartups.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trending Startups in $companySector', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: trendingStartups.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final s = trendingStartups[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompanyDetailScreen(
                                  companyData: s,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
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
                                      backgroundImage: (s['logo'] != null && s['logo'] != '')
                                          ? NetworkImage(s['logo'])
                                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                      radius: 18,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    s['name'] ?? 'Startup',
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
                                      s['sector'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    s['tagline'] ?? '',
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
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CompanyDetailScreen(
                                              companyData: s,
                                              userId: widget.userId,
                                            ),
                                          ),
                                        );
                                      },
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const
Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Colors.blueAccent, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnalyticsDashboardScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ..._recentActivities.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getActivityColor(activity['type']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      activity['icon'],
                      color: _getActivityColor(activity['type']),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['company'],
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          activity['type'] == 'investment' 
                            ? 'Investment: \$${activity['amount']}'
                            : 'Meeting ${activity['status']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    activity['time'],
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'investment':
        return Colors.green;
      case 'meeting':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStartupsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Featured Startups',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _isLoadingStartups
              ? _buildStartupsShimmer()
              : SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _startups.length,
                    itemBuilder: (context, index) {
                      final startup = _startups[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 15),
                        child: StartupCard(
                          startup: startup,
                          onTap: () => _navigateToStartupDetail(startup),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStartupsShimmer() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 15),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.teal, Colors.cyan]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Latest Posts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _isLoadingPosts
              ? _buildPostsShimmer()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: PostCard(post: post),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPostsShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToStartupDetail(Map<String, dynamic> startup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(companyData: startup, userId: widget.userId),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

// Custom Startup Card Widget
class StartupCard extends StatelessWidget {
  final Map<String, dynamic> startup;
  final VoidCallback onTap;

  const StartupCard({
    Key? key,
    required this.startup,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.8),
                    Colors.purpleAccent.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: startup['logo'].isNotEmpty
                      ? NetworkImage(startup['logo'])
                      : const AssetImage('assets/default_company.png') as ImageProvider,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startup['name'] ?? 'Unknown Startup',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (startup['sector']?.isNotEmpty == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          startup['sector'],
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        startup['tagline'] ?? 'Innovative startup solution',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.5',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Post Card Widget
class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post['author_avatar'] != null
                      ? NetworkImage(post['author_avatar'])
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author_name'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        post['created_at'] ?? 'Recently',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (post['content'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post['content'],
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          if (post['image_url'] != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post['image_url'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPostAction(Icons.favorite_border, '${post['likes'] ?? 0}'),
                const SizedBox(width: 20),
                _buildPostAction(Icons.chat_bubble_outline, '${post['comments'] ?? 0}'),
                const SizedBox(width: 20),
                _buildPostAction(Icons.share_outlined, 'Share'),
                const Spacer(),
                _buildPostAction(Icons.bookmark_border, ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// Modal widgets for FAB actions
class CreatePostModal extends StatelessWidget {
  const CreatePostModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Create Post',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Post creation interface would go here'),
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleMeetDialog extends StatelessWidget {
  const ScheduleMeetDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Schedule Meeting'),
      content: const Text('Meeting scheduler interface would go here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schedule'),
        ),
      ],
    );
  }
}

class DiscoverModal extends StatelessWidget {
  const DiscoverModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Discover',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Discovery interface would go here'),
            ),
          ),
        ],
      ),
    );
  }
}

class MarketTrendsModal extends StatelessWidget {
  const MarketTrendsModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Market Trends',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Market trends interface would go here'),
            ),
          ),
        ],
      ),
    );
  }
}