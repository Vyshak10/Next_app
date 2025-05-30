import 'package:flutter/material.dart';
import 'package:next_app/common/color_extension.dart';
import 'package:next_app/view/login/user_type.dart';

class OnboardingPages extends StatefulWidget {
  const OnboardingPages({super.key});

  @override
  State<OnboardingPages> createState() => _OnboardingPagesState();
}

class _OnboardingPagesState extends State<OnboardingPages> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.waving_hand_rounded,
      title: 'Welcome to N.E.X.T.',
      description: 'Your platform for connecting talent with opportunities in the startup ecosystem.',
      color: Colors.blue,
      features: [
        'Connect with innovative companies',
        'Find your dream team',
        'Grow your career',
      ],
    ),
    _OnboardingData(
      icon: Icons.lightbulb_rounded,
      title: 'Discover Startups',
      description: 'Explore innovative startups and companies in various sectors.',
      color: Colors.deepPurple,
      features: [
        'Browse company profiles',
        'View job opportunities',
        'Connect with founders',
      ],
    ),
    _OnboardingData(
      icon: Icons.people_alt_rounded,
      title: 'Connect & Collaborate',
      description: 'Find co-founders, team members, or job opportunities easily.',
      color: Colors.orange,
      features: [
        'Direct messaging',
        'Team collaboration',
        'Meeting scheduling',
      ],
    ),
    _OnboardingData(
      icon: Icons.rocket_launch_rounded,
      title: 'Grow Your Career',
      description: 'Join the next big thing and accelerate your professional journey.',
      color: Colors.green,
      features: [
        'Career insights',
        'Skill development',
        'Professional networking',
      ],
    ),
    _OnboardingData(
      icon: Icons.tips_and_updates_rounded,
      title: 'Getting Started',
      description: 'Here\'s how to make the most of N.E.X.T.',
      color: Colors.teal,
      features: [
        'Complete your profile',
        'Set your preferences',
        'Start connecting',
      ],
      isLastPage: true,
    ),
  ];

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      final selectedRole = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserType()),
      );
      if (selectedRole != null && mounted) {
        Navigator.pushReplacementNamed(
          context, 
          '/signup',
          arguments: {'userType': selectedRole}
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isVerySmallScreen = size.height < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: () async {
                final selectedRole = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserType()),
                );
                
                if (selectedRole != null && mounted) {
                  Navigator.pushReplacementNamed(
                    context, 
                    '/signup',
                    arguments: {'userType': selectedRole}
                  );
                }
              },
              child: const Text('Skip', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.08,
                        vertical: isSmallScreen ? 20 : 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: isVerySmallScreen ? 20 : 40),
                          Icon(
                            page.icon,
                            size: isSmallScreen ? 80 : 100,
                            color: page.color,
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 40),
                          Text(
                            page.title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 20),
                          Text(
                            page.description,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 40),
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: page.features.map((feature) => Padding(
                                padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: page.color,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ),
                          ),
                          if (page.isLastPage) ...[
                            SizedBox(height: isSmallScreen ? 20 : 40),
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: page.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Quick Tips',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildTip(
                                    'Complete your profile to increase visibility',
                                    Icons.person_outline,
                                    page.color,
                                    isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 12),
                                  _buildTip(
                                    'Set your preferences for better matches',
                                    Icons.tune,
                                    page.color,
                                    isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 12),
                                  _buildTip(
                                    'Engage with the community regularly',
                                    Icons.forum_outlined,
                                    page.color,
                                    isSmallScreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: isSmallScreen ? 20 : 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: isSmallScreen ? 16 : 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index ? _pages[_currentPage].color : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 24,
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                    ),
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text, IconData icon, Color color, bool isSmallScreen) {
    return Row(
      children: [
        Icon(icon, color: color, size: isSmallScreen ? 16 : 20),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
          ),
        ),
      ],
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<String> features;
  final bool isLastPage;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.features,
    this.isLastPage = false,
  });
}
