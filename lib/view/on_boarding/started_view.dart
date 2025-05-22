import 'dart:async';

import 'package:flutter/material.dart';
import 'package:next_app/common/color_extension.dart';
import 'package:next_app/view/on_boarding/onboardingpages.dart';

class StartedView extends StatefulWidget {
  const StartedView({super.key});

  @override
  State<StartedView> createState() => _StartedViewState();
}

// We add `SingleTickerProviderStateMixin`
// so our widget can provide a `Ticker` — a "ticker" is needed to drive the animation controller.
class _StartedViewState extends State<StartedView> with SingleTickerProviderStateMixin {
  // _controller will control the animation timing
  late AnimationController _controller;

  // _scaleAnimation will define how the logo scales (grows) using a curve
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Create animation controller with duration of 2 seconds
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 2. Define scale animation with a bounce effect (elasticOut)
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    // 3. Start the animation
    _controller.forward();

    // 4. Navigate to Onboardingpages after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Onboardingpage()),
      );
    });
  }

  // 5. Dispose of the animation controller when not needed to free up resources
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset(
            'assets/img/Icon.png',
            width: 300,
            height: 300,
          ),
        ),

      ),

    );
  }
}
