import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Poppins';

  static TextTheme darkTextTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimaryDark,
      height: 1.12,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryDark,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryDark,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryDark,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      height: 1.5,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryDark,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondaryDark,
      height: 1.5,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondaryDark,
      height: 1.43,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiaryDark,
      height: 1.33,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondaryDark,
      height: 1.33,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textTertiaryDark,
      height: 1.45,
      letterSpacing: 0.5,
    ),
  );

  static TextTheme lightTextTheme = darkTextTheme.copyWith(
    displayLarge: darkTextTheme.displayLarge!.copyWith(color: AppColors.textPrimaryLight),
    displayMedium: darkTextTheme.displayMedium!.copyWith(color: AppColors.textPrimaryLight),
    displaySmall: darkTextTheme.displaySmall!.copyWith(color: AppColors.textPrimaryLight),
    headlineLarge: darkTextTheme.headlineLarge!.copyWith(color: AppColors.textPrimaryLight),
    headlineMedium: darkTextTheme.headlineMedium!.copyWith(color: AppColors.textPrimaryLight),
    headlineSmall: darkTextTheme.headlineSmall!.copyWith(color: AppColors.textPrimaryLight),
    titleLarge: darkTextTheme.titleLarge!.copyWith(color: AppColors.textPrimaryLight),
    titleMedium: darkTextTheme.titleMedium!.copyWith(color: AppColors.textPrimaryLight),
    titleSmall: darkTextTheme.titleSmall!.copyWith(color: AppColors.textPrimaryLight),
    bodyLarge: darkTextTheme.bodyLarge!.copyWith(color: AppColors.textSecondaryLight),
    bodyMedium: darkTextTheme.bodyMedium!.copyWith(color: AppColors.textSecondaryLight),
    bodySmall: darkTextTheme.bodySmall!.copyWith(color: AppColors.textTertiaryLight),
    labelLarge: darkTextTheme.labelLarge!.copyWith(color: AppColors.textPrimaryLight),
    labelMedium: darkTextTheme.labelMedium!.copyWith(color: AppColors.textSecondaryLight),
    labelSmall: darkTextTheme.labelSmall!.copyWith(color: AppColors.textTertiaryLight),
  );
}
