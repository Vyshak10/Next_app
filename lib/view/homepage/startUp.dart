import 'package:flutter/material.dart';
import '../../common_widget/home.dart';
import '../../common_widget/post.dart'; // This should contain your PostScreen class
import '../../common_widget/profile.dart';
import '../../common_widget/messages.dart';

class Startup extends StatefulWidget {
  const Startup({super.key});

  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> with SingleTickerProviderStateMixin {
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
        return HomeScreen(
          onProfileTap: () => _onItemTapped(3),
          userId: userId, // Pass userId to HomeScreen
        );
      case 1:
        // 👇 Updated to use PostScreen instead of PostsPage
        return const PostScreen();
      case 2:
        return MessagesScreen(
          userId: userId,
          conversationId: DateTime.now().millisecondsSinceEpoch.toString(),
        );
      case 3:
        return ProfileScreen(
          userId: userId,
          onBackTap: () => _onItemTapped(0),
        );
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
              _buildNavItem(Icons.add_box_rounded, 'Post', 1),
              _buildNavItem(Icons.chat_bubble_rounded, 'Messages', 2),
              _buildNavItem(Icons.account_circle_rounded, 'Profile', 3),
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