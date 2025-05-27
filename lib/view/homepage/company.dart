import 'package:flutter/material.dart';//company.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common_widget/home.dart';
import '../../common_widget/profile.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  int _selectedIndex = 0;

  final user = Supabase.instance.client.auth.currentUser;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final userId = user?.id ?? '';
    _screens = [
      const HomeScreen(),
      ProfileScreen(userId: userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
      ),
    );
  }
}
