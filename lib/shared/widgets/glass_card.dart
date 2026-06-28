import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.gradient,
    this.border,
    this.onTap,
  });

  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null
                    ? (isDark ? AppColors.glassDark : AppColors.glassLight)
                    : null,
                borderRadius: BorderRadius.circular(borderRadius),
                border: border ??
                    Border.all(
                      color: isDark
                          ? AppColors.glassDarkBorder
                          : AppColors.glassLightBorder,
                      width: 1.0,
                    ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
