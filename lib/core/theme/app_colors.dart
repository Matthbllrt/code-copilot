import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Brand Colors ===
  static const Color primary = Color(0xFFFF4D6D);
  static const Color primaryLight = Color(0xFFFF8FA3);
  static const Color primaryDark = Color(0xFFC9184A);

  static const Color secondary = Color(0xFFFF6B35);
  static const Color secondaryLight = Color(0xFFFF9A76);
  static const Color secondaryDark = Color(0xFFCC4A10);

  static const Color accent = Color(0xFFFFB347);
  static const Color accentPurple = Color(0xFF9B5DE5);
  static const Color accentBlue = Color(0xFF00B4D8);
  static const Color accentGreen = Color(0xFF06D6A0);

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4D6D), Color(0xFFFF6B35)],
  );

  static const LinearGradient romanticGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4D6D), Color(0xFFFF6B9D)],
  );

  static const LinearGradient hotGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B30), Color(0xFFFF6B35)],
  );

  static const LinearGradient funnyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB347), Color(0xFFFFCC02)],
  );

  static const LinearGradient deepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B5DE5), Color(0xFF6A0DAD)],
  );

  static const LinearGradient futureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
  );

  static const LinearGradient randomGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06D6A0), Color(0xFF118AB2)],
  );

  static const LinearGradient dateNightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1B69), Color(0xFF9B5DE5)],
  );

  static const LinearGradient communicationGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
  );

  static const LinearGradient truthOrDareGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E)],
  );

  static const LinearGradient backgroundGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EE)],
  );

  // === Neutrals Dark ===
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color surface2Dark = Color(0xFF2A2A3E);
  static const Color surface3Dark = Color(0xFF363650);
  static const Color cardDark = Color(0xFF252538);
  static const Color borderDark = Color(0xFF3D3D5C);

  // === Neutrals Light ===
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface2Light = Color(0xFFF8F0F4);
  static const Color surface3Light = Color(0xFFF0E6ED);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE8D5E0);

  // === Text Dark ===
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB8B8D0);
  static const Color textTertiaryDark = Color(0xFF7878A0);

  // === Text Light ===
  static const Color textPrimaryLight = Color(0xFF1A0A2E);
  static const Color textSecondaryLight = Color(0xFF5C4A6E);
  static const Color textTertiaryLight = Color(0xFF9E8AAE);

  // === Semantic ===
  static const Color success = Color(0xFF06D6A0);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFFF4D6D);
  static const Color info = Color(0xFF00B4D8);

  // === Glass ===
  static const Color glassDark = Color(0x1AFFFFFF);
  static const Color glassDarkBorder = Color(0x33FFFFFF);
  static const Color glassLight = Color(0x99FFFFFF);
  static const Color glassLightBorder = Color(0x66FFFFFF);
}
