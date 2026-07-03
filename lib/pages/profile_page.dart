import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40.sp,
              backgroundColor: colors.surfaceRaised,
              child: FaIcon(
                FontAwesomeIcons.user,
                size: 36.sp,
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: 16.sp),
            Text(
              'User Profile',
              style: AppTextStyles.titleLarge.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: 6.sp),
            Text(
              'Email: user@example.com',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
