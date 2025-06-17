import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;


import 'company_detail_screen.dart';
import 'company_detail_screen.dart';
import 'package:next_app/common_widget/items_card.dart';
import 'package:next_app/common_widget/NotificationsScreen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onProfileTap;

  const HomeScreen({super.key, this.userProfile, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final secureStorage = const FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();

  String userName = '';
  String selectedSector = 'All';
  List<Map<String, dynamic>> companyData = [];
  bool isLoading = true;
  bool notifyEnabled = true;

  final List<String> sectorOptions = ['All', 'Fintech', 'Healthtech', 'Edtech', 'AI', 'E-commerce'];

  Timer? _debounce;
  late final AnimationController _gradientAnimationController;
  late final Animation<AlignmentGeometry> _gradientBeginAnimation;
  late final Animation<AlignmentGeometry> _gradientEndAnimation;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchStartupData();

    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _gradientBeginAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    ).animate(_gradientAnimationController);

    _gradientEndAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(_gradientAnimationController);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _gradientAnimationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    final token = await secureStorage.read(key: 'auth_token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://yourdomain.com/backend2/public/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userName = data['full_name'] ?? data['email'] ?? '';
      });
    } else {
      print('Failed to fetch user profile: ${response.body}');
    }
  }

  Future<void> fetchStartupData() async {
    setState(() => isLoading = true);
    final token = await secureStorage.read(key: 'auth_token');
    if (token == null) return;

    String url = 'https://yourdomain.com/backend2/public/api/startups';
    final searchQuery = searchController.text.trim();

    final queryParams = {
      if (searchQuery.isNotEmpty) 'search': searchQuery,
      if (selectedSector != 'All') 'sector': selectedSector,
    };

    final uri = Uri.parse(url).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        companyData = List<Map<String, dynamic>>.from(data['startups']);
        isLoading = false;
      });
    } else {
      print('Error fetching startups: ${response.body}');
      setState(() => isLoading = false);
    }
  }

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), fetchStartupData);
  }

  void onSectorSelected(String sector) {
    setState(() => selectedSector = sector);
    fetchStartupData();
  }

  void toggleNotification() {
    setState(() => notifyEnabled = !notifyEnabled);
  }

  void navigateToCompanyDetail(Map<String, dynamic> company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(
          companyData: company,
          userId: company['user_id'] ?? '',
        ),
      ),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  BoxDecoration _getGreetingDecoration({
    required AlignmentGeometry beginAlignment,
    required AlignmentGeometry endAlignment,
  }) {
    final hour = DateTime.now().hour;

    LinearGradient gradient;

    if (hour >= 5 && hour < 12) {
      gradient = LinearGradient(
        colors: [Colors.orange.shade500!, Colors.orange.shade300!],
        begin: beginAlignment,
        end: endAlignment,
      );
    } else if (hour >= 12 && hour < 17) {
      gradient = LinearGradient(
        colors: [Colors.orange.shade400!, Colors.yellow.shade300!],
        begin: beginAlignment,
        end: endAlignment,
      );
    } else if (hour >= 17 && hour < 21) {
      gradient = LinearGradient(
        colors: [Colors.blue.shade800, Colors.blue.shade600],
        begin: beginAlignment,
        end: endAlignment,
      );
    } else {
      gradient = LinearGradient(
        colors: [Colors.black87, Colors.blueGrey.shade800],
        begin: beginAlignment,
        end: endAlignment,
      );
    }

    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchStartupData,
          child: isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading your startups...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          )
              : CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                title: Row(
                  children: [
                    Image.asset('assets/img/Icon.png', height: 32, width: 32),
                    const SizedBox(width: 8),
                    const Text(
                      'N.E.X.T',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                actions: [
                  Tooltip(
                    message: notifyEnabled
                        ? "Tap: View Notifications\nLong Press: Disable Notifications"
                        : "Tap: View Notifications\nLong Press: Enable Notifications",
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MeetingScreen()),
                        );
                      },
                      onLongPress: toggleNotification,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: notifyEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notifyEnabled ? Icons.notifications_active : Icons.notifications_off,
                          color: notifyEnabled ? Colors.blue : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Greeting Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedBuilder(
                    animation: _gradientAnimationController,
                    builder: (context, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        padding: const EdgeInsets.all(20),
                        decoration: _getGreetingDecoration(
                          beginAlignment: _gradientBeginAnimation.value,
                          endAlignment: _gradientEndAnimation.value,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onProfileTap,
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                backgroundImage: widget.userProfile?['avatar_url'] != null &&
                                    widget.userProfile!['avatar_url'] != ''
                                    ? NetworkImage(widget.userProfile!['avatar_url'])
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
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Discover innovative startups',
                                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search startups...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                          searchController.clear();
                          fetchStartupData();
                        })
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),

              // Sector Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sectorOptions.map((sector) {
                            final isSelected = sector == selectedSector;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  sector,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[800],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) => onSectorSelected(sector),
                                selectedColor: Colors.blue,
                                backgroundColor: Colors.grey[200],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Startup List
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final company = companyData[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () => navigateToCompanyDetail(company),
                          child: CompanyCard(
                            logoUrl: company['logo'],
                            name: company['name'],
                            sector: company['sector'],
                            tags: List<String>.from(company['tags'] ?? []),
                          ),
                        ),
                      );
                    },
                    childCount: companyData.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
