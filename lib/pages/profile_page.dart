import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_text_styles.dart';
import 'package:gearrack/pages/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const ProfilePage({super.key, this.onThemeChanged});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(onThemeChanged: widget.onThemeChanged),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onBackground),
        ),
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIconsFill.gear, size: 18.sp, color: colors.primary),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40.sp,
              backgroundColor: colors.surfaceRaised,
              child: PhosphorIcon(
                PhosphorIconsFill.user,
                size: 36.sp,
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: 16.sp),
            Text(
              'User Profile',
              style: AppTextStyles.titleLarge.copyWith(
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: 6.sp),
            Text(
              'More features coming soon',
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