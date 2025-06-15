import 'package:flutter/material.dart';
import '../../common/color_extension.dart';

class UserType extends StatefulWidget {
  const UserType({super.key});

  @override
  State<UserType> createState() => _UserTypeState();
}

class _UserTypeState extends State<UserType> with SingleTickerProviderStateMixin {
  String? _selectedType;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final List<_UserTypeOption> _options = [
    _UserTypeOption(
      title: 'Established Company',
      description: 'Hire talent and grow your team',
      icon: Icons.business_center_rounded,
      color: Colors.deepOrange,
      benefits: [
        'Access to a curated pool of talent',
        'Advanced hiring tools and analytics',
        'Company profile and branding',
        'Direct communication with candidates',
        'Team collaboration features',
      ],
      features: [
        'Post multiple job openings',
        'Review candidate profiles',
        'Schedule interviews',
        'Track hiring metrics',
        'Manage team access',
      ],
    ),
    _UserTypeOption(
      title: 'Startup',
      description: 'Build your founding team and grow fast',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFE97451),
      benefits: [
        'Connect with potential co-founders',
        'Find early-stage talent',
        'Access startup resources',
        'Network with investors',
        'Share your vision',
      ],
      features: [
        'Create startup profile',
        'Post team requirements',
        'Share pitch deck',
        'Track applications',
        'Engage with community',
      ],
    ),
    _UserTypeOption(
      title: 'Job Seeker',
      description: 'Find job opportunities and connections',
      icon: Icons.person_rounded,
      color: Color(0xFF0066CC),
      benefits: [
        'Discover exciting opportunities',
        'Connect with companies directly',
        'Build professional network',
        'Showcase your skills',
        'Get career insights',
      ],
      features: [
        'Create detailed profile',
        'Apply to jobs',
        'Track applications',
        'Receive job alerts',
        'Network with professionals',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/signup',
        arguments: {'userType': _selectedType}
      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select User Type',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: isSmallScreen ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your role',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              Text(
                'Select the type of account you want to create',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 32),
              Expanded(
                child: ListView.builder(
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = _selectedType == option.title;
                    
                    return ScaleTransition(
                      scale: _scaleAnimation,
                      child: Card(
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                        elevation: isSelected ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? option.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedType = option.title;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                                      decoration: BoxDecoration(
                                        color: option.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        option.icon,
                                        color: option.color,
                                        size: isSmallScreen ? 24 : 32,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 12 : 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.title,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: isSmallScreen ? 2 : 4),
                                          Text(
                                            option.description,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: option.color,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                  ],
                                ),
                                if (isSelected) ...[
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  const Divider(),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  Text(
                                    'Key Benefits',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  ...option.benefits.map((benefit) => Padding(
                                    padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: option.color,
                                          size: isSmallScreen ? 16 : 20,
                                        ),
                                        SizedBox(width: isSmallScreen ? 6 : 8),
                                        Expanded(
                                          child: Text(
                                            benefit,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  Text(
                                    'Available Features',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  ...option.features.map((feature) => Padding(
                                    padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star_outline,
                                          color: option.color,
                                          size: isSmallScreen ? 16 : 20,
                                        ),
                                        SizedBox(width: isSmallScreen ? 6 : 8),
                                        Expanded(
                                          child: Text(
                                            feature,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: isSmallScreen ? 12 : 16,
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
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
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

class _UserTypeOption {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> benefits;
  final List<String> features;

  const _UserTypeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.benefits,
    required this.features,
  });
}
