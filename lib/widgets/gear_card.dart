import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
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
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.cardRadius.sp),
            side: BorderSide(
              color: colors.border,
              width: UiConstants.borderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 72.sp,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Condition side-strip — glanceable status at the rail
                    Container(width: 10.sp, color: statusColor),
                    Container(width: 2.sp, color: colors.borderStrong),
                    SizedBox(
                      width: 52.sp,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: categoryColor ?? colors.primary,
                              border: Border(
                                right: BorderSide(
                                  color: colors.border,
                                  width: UiConstants.borderWidth,
                                ),
                              ),
                            ),
                          ),
                          PhosphorIcon(icon, size: 22.sp, color: Colors.white),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: UiConstants.spacingS.sp,
                          right: UiConstants.spacingS.sp,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (gear.brand != null)
                              Text(
                                gear.brand!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56.sp,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _wp.value,
                            style: AppTextStyles.specMedium.copyWith(
                              color: colors.onSurface,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          Text(
                            _wp.unit,
                            style: AppTextStyles.specSmall.copyWith(
                              color: colors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.sp),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
