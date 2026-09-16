import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  // Winky Rough — hand-drawn display for headings (replaces Fraunces)
  static TextStyle get titleLarge => GoogleFonts.winkyRough(
    fontSize: 18.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static TextStyle get titleMedium => GoogleFonts.winkyRough(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static TextStyle get titleSmall => GoogleFonts.winkyRough(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  // Spec mono — tabular readout for weights / litres / counts (trail-tag feel)
  static TextStyle get specMedium => GoogleFonts.ibmPlexMono(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static TextStyle get specSmall => GoogleFonts.ibmPlexMono(
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    color: AppColors.black,
  );

  // Inter — clean utilitarian sans for body / UI
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  // Labels — lighter weight for metadata
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );
}
