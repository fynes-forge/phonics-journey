import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class RocketHero extends StatelessWidget {
  final int totalStars;
  final Color themeColor;

  const RocketHero({
    super.key, 
    required this.totalStars, 
    required this.themeColor
  });

  @override
  Widget build(BuildContext context) {
    // Milestone Colors
    Color rocketColor = Colors.redAccent;
    if (totalStars >= 10) rocketColor = Colors.greenAccent;
    if (totalStars >= 30) rocketColor = Colors.orangeAccent;
    if (totalStars >= 60) rocketColor = Colors.purpleAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Rocket Icon
        Icon(
          Icons.rocket_launch_rounded,
          size: 40,
          color: rocketColor,
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2.seconds, color: Colors.white30)
        .shake(hz: 2, curve: Curves.easeInOut), // Floating effect

        // The Engine Glow
        Container(
          width: 12,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: rocketColor.withOpacity(0.8),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
      ],
    );
  }
}