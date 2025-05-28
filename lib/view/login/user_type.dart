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
    ),
    _UserTypeOption(
      title: 'Startup',
      description: 'Build your founding team and grow fast',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFE97451),
    ),
    _UserTypeOption(
      title: 'Job Seeker',
      description: 'Find job opportunities and connections',
      icon: Icons.person_rounded,
      color: Color(0xFF0066CC),
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
    if (_selectedType == null) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
    Navigator.pop(context, _selectedType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Role'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Icon(Icons.account_circle_rounded, size: 64, color: Colors.blue.shade700),
                  const SizedBox(height: 12),
                  Text(
                    'Who are you?',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                  const SizedBox(height: 4),
                  const Text('Select your role to get started', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 32),
              ..._options.map((option) {
                final isSelected = _selectedType == option.title;
                return ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? option.color.withOpacity(0.13) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? option.color : Colors.grey.shade300,
                        width: isSelected ? 3 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: option.color.withOpacity(0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _selectedType = option.title),
                      leading: CircleAvatar(
                        backgroundColor: option.color.withOpacity(0.15),
                        child: Icon(option.icon, color: option.color, size: 32),
                        radius: 28,
                      ),
                      title: Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? option.color : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? option.color.withOpacity(0.8) : Colors.grey[700],
                        ),
                      ),
                      trailing: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSelected ? 1.0 : 0.0,
                        child: isSelected
                            ? Icon(Icons.check_circle_rounded, color: option.color, size: 28)
                            : const SizedBox(width: 28),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedType == null || _isLoading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  const _UserTypeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
