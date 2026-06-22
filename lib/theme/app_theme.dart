import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'ui_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnAccent,
        error: const Color(0xFFB00020),
        onError: const Color(0xFFFFFFFF),
        background: AppColors.lightBackground,
        onBackground: AppColors.lightTextPrimary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: TextTheme(
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );

    // Compose a set of common component themes that rely on the color palette
    final colors = base.colorScheme;

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 12.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.borderRadius),
          borderSide: BorderSide(
            color: AppColors.lightBorder,
            width: UiConstants.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.borderRadius),
          borderSide: BorderSide(
            color: AppColors.lightBorder,
            width: UiConstants.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.borderRadius),
          borderSide: BorderSide(
            color: AppColors.lightPrimary,
            width: UiConstants.borderWidth,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.buttonRadius),
          ),
          textStyle: AppTextStyles.bodyMedium,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(
            color: AppColors.lightBorder,
            width: UiConstants.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.buttonRadius),
          ),
          textStyle: AppTextStyles.bodyMedium,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: AppTextStyles.bodyMedium,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        disabledColor: AppColors.lightSurfaceSunken,
        selectedColor: AppColors.lightPrimary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        secondaryLabelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.lightOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.chipRadius),
        ),
      ),

      // Card color is set here; shape/margins should be used on Card widgets
      // or added to `Card` when a custom shape is required.
      cardColor: AppColors.lightSurface,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurfaceRaised,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurfaceRaised,
        selectedItemColor: colors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        showUnselectedLabels: true,
      ),

      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnPrimary,
        error: const Color(0xFFB00020),
        onError: const Color(0xFFFFFFFF),
        background: AppColors.darkBackground,
        onBackground: AppColors.darkTextPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: TextTheme(
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.white),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.white),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.white),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),
    );

    final colors = base.colorScheme;

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 12.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.borderRadius),
          borderSide: BorderSide(
            color: AppColors.darkBorder,
            width: UiConstants.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.borderRadius),
          borderSide: BorderSide(
            color: AppColors.darkBorder,
            width: UiConstants.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.borderRadius),
          borderSide: BorderSide(
            color: AppColors.darkPrimary,
            width: UiConstants.borderWidth,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.buttonRadius),
          ),
          textStyle: AppTextStyles.bodyMedium.copyWith(color: colors.onPrimary),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(
            color: AppColors.darkBorder,
            width: UiConstants.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.buttonRadius),
          ),
          textStyle: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: AppTextStyles.bodyMedium.copyWith(color: colors.primary),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        disabledColor: AppColors.darkSurfaceSunken,
        selectedColor: AppColors.darkPrimary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        secondaryLabelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.chipRadius),
        ),
      ),

      // Card color is set here; shape/margins should be used on Card widgets
      // or added to `Card` when a custom shape is required.
      cardColor: AppColors.darkSurface,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurfaceRaised,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceRaised,
        selectedItemColor: colors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        showUnselectedLabels: true,
      ),

      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
    );
  }
}
