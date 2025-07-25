import 'dart:async';

import 'package:flutter/material.dart';
import 'package:next_app/common/color_extension.dart';
import 'package:next_app/view/on_boarding/onboardingpages.dart';

class StartedView extends StatefulWidget {
  const StartedView({super.key});

  @override
  State<StartedView> createState() => _StartedViewState();
}

class _StartedViewState extends State<StartedView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();

    // Navigate to onboarding after animation completes
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset('assets/img/Icon.png', height: 200, width: 200),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      children: [
                        Text(
                          'N.E.X.T.',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _AnimatedNextFullForm(controller: _controller),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                            ),
                          ),
                          child: Text(
                            'Your next opportunity awaits.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedNextFullForm extends StatelessWidget {
  final AnimationController controller;
  _AnimatedNextFullForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Each word fades in sequentially
    final words = [
      'Nurturing',
      'Entrepreneurs',
      'and',
      'eXeptional',
      'Talents',
    ];
    final intervals = [
      const Interval(0.1, 0.3, curve: Curves.easeIn),
      const Interval(0.3, 0.5, curve: Curves.easeIn),
      const Interval(0.5, 0.6, curve: Curves.easeIn),
      const Interval(0.6, 0.8, curve: Curves.easeIn),
      const Interval(0.8, 1.0, curve: Curves.easeIn),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(words.length, (i) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Opacity(
                opacity: intervals[i].transform(controller.value).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    words[i],
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blueGrey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
