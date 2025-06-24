import 'package:flutter/material.dart';

mixin AnimatedGreetingGradientMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController gradientAnimationController;
  late Animation<AlignmentGeometry> gradientBeginAnimation;
  late Animation<AlignmentGeometry> gradientEndAnimation;

  @override
  void initState() {
    super.initState();
    gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    gradientBeginAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    ).animate(gradientAnimationController);

    gradientEndAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(gradientAnimationController);
  }

  @override
  void dispose() {
    gradientAnimationController.dispose();
    super.dispose();
  }

  LinearGradient getGreetingGradient(AlignmentGeometry begin, AlignmentGeometry end) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return LinearGradient(colors: [Colors.orange.shade500, Colors.orange.shade300], begin: begin, end: end);
    } else if (hour >= 12 && hour < 17) {
      return LinearGradient(colors: [Colors.orange.shade400, Colors.yellow.shade300], begin: begin, end: end);
    } else if (hour >= 17 && hour < 21) {
      return LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600], begin: begin, end: end);
    } else {
      return LinearGradient(colors: [Colors.black87, Colors.blueGrey.shade800], begin: begin, end: end);
    }
  }
} 