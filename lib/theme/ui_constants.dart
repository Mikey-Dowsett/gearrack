import 'package:flutter/material.dart';

/// Central UI constants (spacing, radii, stroke widths) used across the app.
/// Keep values simple and semantic so widgets can reference these tokens instead
/// of hard-coded numbers.
class UiConstants {
  // Spacing
  static const double spacingXS = 6.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;

  // Border radii
  static const double borderRadius = 10.0;
  static const double cardRadius = 10.0;
  static const double chipRadius = 20.0;
  static const double buttonRadius = 10.0;

  // Stroke widths
  static const double borderWidth = 2.0;

  // Elevation
  static const double cardElevation = 2.0;

  // Icon sizes
  static const double iconSmall = 14.0;
  static const double iconMedium = 18.0;
  static const double iconLarge = 24.0;

  // Misc
  static const double inputFieldHeight = 48.0;
  static const double avatarSize = 40.0;
}
