import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ui_constants.dart';

class InfoCard extends StatelessWidget {
  final Object icon;
  final String title;
  final String value;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Card.filled(
      color: colors.surface,
      elevation: UiConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
        side: BorderSide(color: colors.border, width: UiConstants.borderWidth),
      ),
      child: Padding(
        padding: EdgeInsets.all(UiConstants.spacingM.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  icon as FaIconData,
                  size: UiConstants.iconMedium.sp,
                  color: colors.onSurface,
                ),
                SizedBox(width: UiConstants.spacingXS.sp),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: UiConstants.spacingS.sp),
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
