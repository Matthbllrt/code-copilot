import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.gradient,
  });

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: gradient ??
                (isDark
                    ? AppColors.backgroundGradientDark
                    : AppColors.backgroundGradientLight),
          ),
        ),
        // Animated orbs
        Positioned(
          top: -80,
          right: -60,
          child: _Orb(
            color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.12),
            size: 250,
            animDuration: const Duration(seconds: 8),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: _Orb(
            color: AppColors.accentPurple.withOpacity(isDark ? 0.12 : 0.08),
            size: 300,
            animDuration: const Duration(seconds: 10),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: -40,
          child: _Orb(
            color: AppColors.secondary.withOpacity(isDark ? 0.08 : 0.06),
            size: 180,
            animDuration: const Duration(seconds: 12),
          ),
        ),
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.color,
    required this.size,
    required this.animDuration,
  });

  final Color color;
  final double size;
  final Duration animDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: animDuration,
          curve: Curves.easeInOut,
        )
        .blur(
          begin: const Offset(40, 40),
          end: const Offset(60, 60),
          duration: animDuration,
          curve: Curves.easeInOut,
        );
  }
}

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.gradient,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = true,
  });

  final Widget child;
  final Gradient? gradient;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: AnimatedGradientBackground(
        gradient: gradient,
        child: child,
      ),
    );
  }
}
