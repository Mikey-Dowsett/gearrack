import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_text_styles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40.sp,
              child: FaIcon(FontAwesomeIcons.user, size: 36.sp),
            ),
            SizedBox(height: 16.sp),
            Text(
              'User Profile',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.sp),
            Text('Email: user@example.com', style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
