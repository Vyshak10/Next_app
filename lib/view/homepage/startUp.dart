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
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic>? _userProfile;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    final userId = user?.id ?? '';
    _loadUserProfile(userId);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  Future<void> _loadUserProfile(String userId) async {
    print('Attempting to load user profile for userId: $userId');
    try {
      final profileData = await supabase
          .from('profiles')
          .select('name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      print('Fetched profileData: $profileData');

      if (mounted) {
        print('Widget is mounted, setting state with profileData');
        setState(() {
          _userProfile = profileData;
        });
      } else {
        print('Widget is not mounted, skipping setState');
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Helper method to build the current screen based on selected index
  Widget _buildScreenWidget(int index) {
    final userId = user?.id ?? '';
    switch (index) {
      case 0:
        return HomeScreen(onProfileTap: () => _onItemTapped(3), userProfile: _userProfile);
      case 1:
        return PostScreen(userId: userId);
      case 2:
        return MessagesScreen(userId: userId);
      case 3:
        return ProfileScreen(userId: userId, onBackTap: () => _onItemTapped(0));
      default:
        return Center(child: Text('Error: Invalid index $index'));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print('Startup selected index: \$_selectedIndex');
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Startup build called with index: \$_selectedIndex');
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
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildScreenWidget(0),
              _buildScreenWidget(1),
              _buildScreenWidget(2),
              _buildScreenWidget(3),
            ],
          ),
        ),
        bottomNavigationBar: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 24, end: isSelected ? 28 : 24),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, size, child) {
                  return Icon(
                    icon,
                    color: isSelected ? Colors.blueAccent : Colors.grey[600],
                    size: size,
                  );
                },
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isSelected ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ) : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}