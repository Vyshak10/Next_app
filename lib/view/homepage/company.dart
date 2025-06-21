import 'package:flutter/material.dart';//company.dart

import '../../common_widget/home.dart';
import '../../common_widget/profile.dart';
import '../../common_widget/messages.dart';

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
  final secureStorage = FlutterSecureStorage();
  late final List<Widget> _screens;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    fetchUserData(); // Fetch userId + name, then setup _screens
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print('CompanyScreen selected index: \$_selectedIndex');
    });
  }

  Future<void> fetchUserData() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');

    final response = await http.get(
      Uri.parse('https://indianrupeeservices.in/NEXT/backend/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final userId = data['id'];

      setState(() {
        userName = data['full_name'] ?? data['email'] ?? '';
        _screens = [
          HomeScreen(onProfileTap: () => _onItemTapped(2)),
          const MessagesPage(),
          ProfileScreen(userId: userId, onBackTap: () => _onItemTapped(0)),
        ];
      });
    } else {
      print('Failed to fetch user data');
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
    switch (_selectedIndex) {
      case 0:
        return PreferredSize(
          preferredSize: Size.fromHeight(0.0),
          child: Container(),
        );      
      case 1:
        return AppBar(
          title: const Text('Messages', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: null,
          automaticallyImplyLeading: false,
        );    
      case 2:
        return AppBar(
          title: const Text('Profile', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: null,
          automaticallyImplyLeading: false,
        );      
      default:
        return AppBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('CompanyScreen build called with index: \$_selectedIndex');
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
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
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
                  _buildNavItem(Icons.chat_bubble_rounded, 'Messages', 1),
                  _buildNavItem(Icons.account_circle_rounded, 'Profile', 2),
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
    return GestureDetector(
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
              curve: Curves.easeInOut,
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
              curve: Curves.easeInOut,
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
    );
  }
}
