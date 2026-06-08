import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../pages/gear_page.dart';
import '../models/gear.dart';
import '../models/condition.dart';

class GearCard extends StatelessWidget {
  final Gear gear;

  const GearCard({super.key, required this.gear});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final Color statusColor = gear.condition == Condition.Good
        ? AppColors.statusGood
        : gear.condition == Condition.Worn
        ? AppColors.statusWorn
        : AppColors.statusRetired;

    final String conditionText = gear.condition == Condition.Good
        ? 'Good'
        : gear.condition == Condition.Worn
        ? 'Worn'
        : 'Retired';

    return Padding(
      padding: EdgeInsets.only(
        right: 8.0.w,
        left: 8.0.w,
        top: 4.0.h,
        bottom: 4.0.h,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GearPage(gear: gear)),
          );
        },
        child: Card.filled(
          color: colors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              10.0.sp,
            ), // Optional: sets corner radius
            side: BorderSide(
              color: colors.border, // Border color
              width: 2.0, // Border width
            ),
          ),
          child: SizedBox(
            height: 70.sp,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 50.sp,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.sp),
                            bottomLeft: Radius.circular(10.sp),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment(-0.8, -0.8),
                            stops: [0.0, 0.5, 0.5, 1.0],
                            colors: [
                              colors.surfaceRaised,
                              colors.surfaceRaised,
                              colors.surfaceSunken,
                              colors.surfaceSunken,
                            ],
                            tileMode: TileMode.repeated,
                          ),
                        ),
                      ),
                      FaIcon(
                        gear.icon as FaIconData,
                        size: 25.sp,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(gear.name, style: AppTextStyles.titleLarge),
                      Text(gear.brand, style: AppTextStyles.bodyMedium),
                      SizedBox(height: 8.sp),
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 4.0.sp),
                            child: CircleAvatar(
                              backgroundColor: statusColor,
                              radius: 5.0.sp,
                            ),
                          ),
                          Text(conditionText, style: AppTextStyles.labelMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                VerticalDivider(
                  width: 20,
                  thickness: 2,
                  indent: 0,
                  endIndent: 0,
                  color: colors.borderStrong,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8.w, right: 16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gear.weight.toString(),
                        style: AppTextStyles.titleLarge,
                      ),
                      Text(
                        "KG",
                        style: AppTextStyles.bodyMedium,
                      ), // Should use system setting
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
