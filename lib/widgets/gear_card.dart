import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../pages/gear_page.dart';
import '../models/gear_item.dart';
import '../models/condition.dart';
import '../utils/icon_registry.dart';
import '../utils/weight_formatter.dart';
import '../theme/ui_constants.dart';

class GearCard extends StatelessWidget {
  final GearItem gear;
  final String categoryIcon;
  final Color? categoryColor;
  final VoidCallback? onGearUpdated;

  const GearCard({
    super.key,
    required this.gear,
    required this.categoryIcon,
    this.categoryColor,
    this.onGearUpdated,
  });

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

    final icon = IconRegistry.resolve(categoryIcon);
    final _wp = formatWeightParts(gear.weightGrams);

    return Padding(
      padding: EdgeInsets.only(
        right: UiConstants.spacingM.sp,
        left: UiConstants.spacingM.sp,
        top: UiConstants.spacingXS.sp,
        bottom: UiConstants.spacingXS.sp,
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
          elevation: UiConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
            side: BorderSide(
              color: colors.border,
              width: UiConstants.borderWidth,
            ),
          ),
          child: SizedBox(
            height: 72.sp,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 52.sp,
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
                        icon,
                        size: 22.sp,
                        color: categoryColor ?? colors.primary,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: UiConstants.spacingS.sp,
                    right: UiConstants.spacingXS.sp,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gear.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      if (gear.brand != null)
                        Text(
                          gear.brand!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      SizedBox(height: 4.sp),
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 4.0.sp),
                            child: CircleAvatar(
                              backgroundColor: statusColor,
                              radius: 5.0.sp,
                            ),
                          ),
                          Text(
                            conditionText,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                VerticalDivider(
                  width: 20.sp,
                  thickness: UiConstants.borderWidth,
                  indent: 0,
                  endIndent: 0,
                  color: colors.borderStrong,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8.w, right: 12.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            _wp.value,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            _wp.unit,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
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
