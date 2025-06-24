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
    final selectedOption = _options.firstWhere((o) => o.title == _selectedType, orElse: () => _options[0]);
    final topIcon = _selectedType == 'Startup'
        ? Icons.rocket_launch_rounded
        : Icons.business_center_rounded;
    final topIconColor = _selectedType == 'Startup'
        ? const Color(0xFFE97451)
        : Colors.deepOrange;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Themed top icon
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: topIconColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: topIconColor.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(topIcon, color: topIconColor, size: 72),
                  ),
                  Text(
                    'Choose your role',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let's get you started on your journey!",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the type of account you want to create',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: size.width > 500 ? 500 : size.width * 0.95,
                    child: Column(
                      children: List.generate(_options.length, (index) {
                        final option = _options[index];
                        final isSelected = _selectedType == option.title;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? option.color.withOpacity(0.18) : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: option.color.withOpacity(0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                            ],
                            border: Border.all(
                              color: isSelected ? option.color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  _selectedType = option.title;
                                });
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: option.color.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(option.icon, color: option.color, size: 32),
                                ),
                                title: Text(
                                  option.title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[900],
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    option.description,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.blueGrey[400],
                                    ),
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: option.color, size: 28)
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Benefits/features preview for selected role
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _selectedType != null
                        ? Padding(
                            key: ValueKey(_selectedType),
                            padding: const EdgeInsets.only(top: 24, bottom: 8),
                            child: Column(
                              children: [
                                Text(
                                  'Why choose ${selectedOption.title}?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...selectedOption.benefits.map((b) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              b,
                                              style: const TextStyle(color: Colors.white, fontSize: 15),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: 400,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          boxShadow: _selectedType != null
                              ? [
                                  BoxShadow(
                                    color: topIconColor.withOpacity(0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Continue'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
