import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  static TextStyle get titleLarge => GoogleFonts.nunito(
    fontSize: 18.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
  );

  static TextStyle get titleMedium => GoogleFonts.nunito(
    fontSize: 16.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
  );

  static TextStyle get titleSmall => GoogleFonts.nunito(
    fontSize: 14.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
  );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static TextStyle get labelLarge => GoogleFonts.nunito(
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  static TextStyle get labelMedium => GoogleFonts.nunito(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  static TextStyle get labelSmall => GoogleFonts.nunito(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );
}
