//startup_training_room.dart
import 'package:flutter/material.dart';
import 'dart:async';

class StartupTrainingRoom extends StatefulWidget {
  final String startupName;
  final String sinNumber;

  const StartupTrainingRoom({
    super.key,
    required this.startupName,
    required this.sinNumber,
  });

  @override
  State<StartupTrainingRoom> createState() => _StartupTrainingRoomState();
}

class _StartupTrainingRoomState extends State<StartupTrainingRoom> with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  Timer? _verificationCheckTimer;
  bool _isChecking = false;

  final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      title: 'Welcome to NEXT!',
      description: 'Your startup verification is in progress. While you wait, let\'s explore the platform!',
      icon: Icons.rocket_launch_rounded,
      color: Colors.blueAccent,
    ),
    TutorialStep(
      title: 'Dashboard Overview',
      description: 'Your home screen shows key metrics, upcoming meetings, and important notifications at a glance.',
      icon: Icons.dashboard_rounded,
      color: Colors.purple,
    ),
    TutorialStep(
      title: 'Connect with Investors',
      description: 'Browse and connect with investors who are interested in your industry. Schedule meetings directly!',
      icon: Icons.handshake_rounded,
      color: Colors.orange,
    ),
    TutorialStep(
      title: 'Messaging System',
      description: 'Chat with investors, mentors, and other startups. Build your network and collaborate!',
      icon: Icons.chat_bubble_rounded,
      color: Colors.green,
    ),
    TutorialStep(
      title: 'Analytics & Insights',
      description: 'Track your profile views, connection requests, and engagement metrics to optimize your presence.',
      icon: Icons.analytics_rounded,
      color: Colors.teal,
    ),
    TutorialStep(
      title: 'Profile Management',
      description: 'Keep your startup profile updated with latest achievements, team info, and funding goals.',
      icon: Icons.business_center_rounded,
      color: Colors.indigo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Simulate periodic verification checks (every 10 seconds)
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    // TODO: Replace with actual API call to check verification status
    // For now, this is a placeholder
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate random verification result for demo (remove in production)
    // In production, this should check the actual backend status
    final isVerified = DateTime.now().second % 30 == 0; // Random chance
    
    if (isVerified) {
      _verificationCheckTimer?.cancel();
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/verification-success',
          arguments: {'startupName': widget.startupName},
        );
      }
    }
    
    setState(() => _isChecking = false);
  }

  void _nextStep() {
    if (_currentStep < _tutorialSteps.length - 1) {
      setState(() => _currentStep++);
      _slideController.forward(from: 0);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _slideController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTutorial = _tutorialSteps[_currentStep];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildVerificationStatus(),
                    const SizedBox(height: 32),
                    _buildTutorialContent(currentTutorial),
                    const SizedBox(height: 24),
                    _buildProgressIndicator(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Training Room',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Welcome, ${widget.startupName}!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 48),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Verification in Progress',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'SIN: ${widget.sinNumber}',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.9)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estimated time: 24-48 hours',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Our team is reviewing your startup information',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialContent(TutorialStep step) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _slideController,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: step.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, color: step.color, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                step.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                step.description,
                style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_tutorialSteps.length, (index) {
        final isActive = index == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.blueAccent),
                ),
                child: const Text('Previous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _currentStep < _tutorialSteps.length - 1 ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _currentStep < _tutorialSteps.length - 1 ? 'Next' : 'Completed',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
