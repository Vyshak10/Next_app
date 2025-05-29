import 'package:flutter/material.dart';//company.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common_widget/home.dart';
import '../../common_widget/profile.dart';
import '../../common_widget/messages.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final user = Supabase.instance.client.auth.currentUser;
  late final List<Widget> _screens;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String userName = '';

  @override
  void initState() {
    super.initState();
    final userId = user?.id ?? '';
    _screens = [
      const HomeScreen(),
      MessagesScreen(userId: userId),
      ProfileScreen(userId: userId),
    ];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    fetchUserName();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> fetchUserName() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      setState(() {
        userName = response['full_name'] ?? user.email ?? '';
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      title: null,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Greeting and user name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getGreeting(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName.isNotEmpty ? userName : 'User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
            label: 'Home'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded, color: Colors.white),
            label: 'Messages'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            activeIcon: Icon(Icons.account_circle_rounded, color: Colors.white),
            label: 'Profile'
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
        backgroundColor: Colors.blue,
      ),
    );
  }
}
