import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../pages/gear_page.dart';
import '../models/gear_item.dart';
import '../models/condition.dart';

class GearCard extends StatelessWidget {
  final GearItem gear;
  final VoidCallback? onGearUpdated;

  const GearCard({super.key, required this.gear, this.onGearUpdated});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final condition = gear.conditionEnum;

    final Color statusColor = condition == Condition.Good
        ? AppColors.statusGood
        : condition == Condition.Worn
        ? AppColors.statusWorn
        : AppColors.statusRetired;

    final String conditionText = condition == Condition.Good
        ? 'Good'
        : condition == Condition.Worn
        ? 'Worn'
        : 'Retired';

    // Use the category icon as a stand-in. In future iterations, gear items
    // may have their own icon. For now we use a default suitcase icon.
    final Object icon = FontAwesomeIcons.suitcase;

    return Padding(
      padding: EdgeInsets.only(
        right: 8.0.w,
        left: 8.0.w,
        top: 4.0.h,
        bottom: 4.0.h,
      ),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push<GearItem>(
            context,
            MaterialPageRoute(builder: (context) => GearPage(gear: gear)),
          );
          if (result != null) {
            onGearUpdated?.call();
          }
        },
        child: Card.filled(
          color: colors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0.sp),
            side: BorderSide(color: colors.border, width: 2.0),
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
                            end: const Alignment(-0.8, -0.8),
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
                        icon as FaIconData,
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
                      if (gear.brand != null)
                        Text(gear.brand!, style: AppTextStyles.bodyMedium),
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
                        gear.weightGrams.toStringAsFixed(0),
                        style: AppTextStyles.titleLarge,
                      ),
                      Text('g', style: AppTextStyles.bodyMedium),
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
