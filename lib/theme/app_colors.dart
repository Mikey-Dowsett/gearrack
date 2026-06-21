import 'package:flutter/material.dart';

/// Centralized color palette for the app.
///
/// This file keeps the full light/dark palettes as static constants and
/// exposes a runtime accessor `AppColors.of(context)` which returns a
/// small object with semantic colors appropriate for the current theme.
class AppColors {
  // Status Colors (Shared)
  static const Color statusNew = Color(0xFF459B61);
  static const Color statusGood = Color(0xFF809E5A);
  static const Color statusWorn = Color(0xFFCA933E);
  static const Color statusRetired = Color(0xFF90847A);

  // Light Mode (Field)
  static const Color lightBackground = Color(0xFFEEE9DF);
  static const Color lightSurface = Color(0xFFFAF6EF);
  static const Color lightSurfaceRaised = Color(0xFFE5DFD3);
  static const Color lightSurfaceSunken = Color(0xFFDCD5C7);
  static const Color lightTextPrimary = Color(0xFF2C271E);
  static const Color lightTextSecondary = Color(0xFF5C564A);
  static const Color lightTextDisabled = Color(0xFF867F73);
  static const Color lightBorder = Color(0xFFD2CBBE);
  static const Color lightBorderStrong = Color(0xFFBEB6A8);
  static const Color lightPrimary = Color(0xFF385A41);
  static const Color lightOnPrimary = Color(0xFFF2F9F3);
  static const Color lightPrimaryContainer = Color(0xFFD0E7D4);
  static const Color lightPrimaryMuted = Color(0xFF708F77);
  static const Color lightAccent = Color(0xFF3A714B);
  static const Color lightOnAccent = Color(0xFFFAF9F0);
  static const Color lightSecondary = Color(0xFF72804F);
  static const Color lightTertiary = Color(0xFFAE6739);
  static const Color lightTertiaryContainer = Color(0xFFF5D8C1);

  // Dark Mode (Night)
  static const Color darkBackground = Color(0xFF131914);
  static const Color darkSurface = Color(0xFF1D251F);
  static const Color darkSurfaceRaised = Color(0xFF273129);
  static const Color darkSurfaceSunken = Color(0xFF323C34);
  static const Color darkTextPrimary = Color(0xFFECE9E1);
  static const Color darkTextSecondary = Color(0xFFB0ACA0);
  static const Color darkTextDisabled = Color(0xFF828175);
  static const Color darkBorder = Color(0xFF333C35);
  static const Color darkBorderStrong = Color(0xFF465048);
  static const Color darkPrimary = Color(0xFF77B487);
  static const Color darkOnPrimary = Color(0xFF0B140D);
  static const Color darkPrimaryContainer = Color(0xFF2B4431);
  static const Color darkPrimaryMuted = Color(0xFF6B9174);
  static const Color darkAccent = Color(0xFF5CAD72);
  static const Color darkOnAccent = Color(0xFF0D1A10);
  static const Color darkSecondary = Color(0xFF96A672);
  static const Color darkTertiary = Color(0xFFD99165);
  static const Color darkTertaryContainer = Color(0xFF5E402F);

  // Convenience static colors used by some legacy code paths.
  // These are simple aliases and not context-aware.
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Return a context-aware palette (semantic colors) for the current theme.
  static AppColorPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? AppColorPalette._dark()
        : AppColorPalette._light();
  }
}

/// A small object with semantic color properties for use in widgets.
/// Use `AppColors.of(context).primary`, `...background`, etc.
class AppColorPalette {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color primaryMuted;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color onSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color borderStrong;
  final Color secondary;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color error;
  final Color statusNew;
  final Color statusGood;
  final Color statusWorn;
  final Color statusRetired;

  const AppColorPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.primaryMuted,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.onSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.borderStrong,
    required this.secondary,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.error,
    required this.statusNew,
    required this.statusGood,
    required this.statusWorn,
    required this.statusRetired,
  });

  factory AppColorPalette._light() {
    return const AppColorPalette(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightOnPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      primaryMuted: AppColors.lightPrimaryMuted,
      accent: AppColors.lightAccent,
      onAccent: AppColors.lightOnAccent,
      background: AppColors.lightBackground,
      onBackground: AppColors.lightTextPrimary,
      surface: AppColors.lightSurface,
      surfaceRaised: AppColors.lightSurfaceRaised,
      surfaceSunken: AppColors.lightSurfaceSunken,
      onSurface: AppColors.lightTextPrimary,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      border: AppColors.lightBorder,
      borderStrong: AppColors.lightBorderStrong,
      secondary: AppColors.lightSecondary,
      tertiary: AppColors.lightTertiary,
      tertiaryContainer: AppColors.lightTertiaryContainer,
      error: Color(0xFFB00020),
      statusNew: AppColors.statusNew,
      statusGood: AppColors.statusGood,
      statusWorn: AppColors.statusWorn,
      statusRetired: AppColors.statusRetired,
    );
  }

  factory AppColorPalette._dark() {
    return const AppColorPalette(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      primaryMuted: AppColors.darkPrimaryMuted,
      accent: AppColors.darkAccent,
      onAccent: AppColors.darkOnAccent,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface,
      surfaceRaised: AppColors.darkSurfaceRaised,
      surfaceSunken: AppColors.darkSurfaceSunken,
      onSurface: AppColors.darkTextPrimary,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      border: AppColors.darkBorder,
      borderStrong: AppColors.darkBorderStrong,
      secondary: AppColors.darkSecondary,
      tertiary: AppColors.darkTertiary,
      tertiaryContainer: AppColors.darkTertaryContainer,
      error: Color(0xFFB00020),
      statusNew: AppColors.statusNew,
      statusGood: AppColors.statusGood,
      statusWorn: AppColors.statusWorn,
      statusRetired: AppColors.statusRetired,
    );
  }
}
