import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common_widget/home.dart';
import '../../common_widget/post.dart';
import '../../common_widget/profile.dart';
import '../../common_widget/messages.dart';

class Startup extends StatefulWidget {
  const Startup({super.key});

  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final user = Supabase.instance.client.auth.currentUser;
  late final List<Widget> _screens;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final userId = user?.id ?? '';
    _screens = [
      const HomeScreen(),
      PostScreen(userId: userId),
      MessagesScreen(userId: userId),
      ProfileScreen(userId: userId),
    ];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
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
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.blue.withOpacity(0.15),
          highlightColor: Colors.blue.withOpacity(0.08),
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, color: Colors.blue),
              label: 'Home'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_rounded),
              activeIcon: Icon(Icons.add_box_rounded, color: Colors.blue),
              label: 'Post'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded, color: Colors.blue),
              label: 'Messages'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              activeIcon: Icon(Icons.account_circle_rounded, color: Colors.blue),
              label: 'Profile'
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 8,
          backgroundColor: Colors.white,
          enableFeedback: true,
        ),
      ),
    );
  }
}