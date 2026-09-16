import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../theme/ui_constants.dart';
import '../models/pack.dart';
import '../utils/weight_formatter.dart';

class PackCard extends StatelessWidget {
  final Pack pack;
  final String? bagName;
  final double totalWeightGrams;
  final int totalItems;
  final double? capacityLiters;
  final VoidCallback? onTap;
  final VoidCallback? onPackUpdated;

  const PackCard({
    super.key,
    required this.pack,
    this.bagName,
    required this.totalWeightGrams,
    required this.totalItems,
    this.capacityLiters,
    this.onTap,
    this.onPackUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final _wp = formatWeightParts(totalWeightGrams);

    return Padding(
      padding: EdgeInsets.only(
        right: UiConstants.spacingM.sp,
        left: UiConstants.spacingM.sp,
        top: UiConstants.spacingXS.sp,
        bottom: UiConstants.spacingXS.sp,
      ),
      child: GestureDetector(
        onTap: onTap,
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
              // Gradient section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(UiConstants.cardRadius.sp),
                    topRight: Radius.circular(UiConstants.cardRadius.sp),
                  ),
                  color: colors.primary,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.border,
                      width: UiConstants.borderWidth,
                    ),
                  ),
                ),
                padding: EdgeInsets.all(12.sp),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pack.name,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: colors.onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (pack.description != null &&
                              pack.description!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                top: UiConstants.spacingXS.sp,
                              ),
                              child: Text(
                                pack.description!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (bagName != null && bagName!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                top: UiConstants.spacingXS.sp,
                              ),
                              child: Text(
                                bagName!,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: UiConstants.spacingS.sp),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _wp.value +
                                  (_wp.unit == 'kg' ? ' ' + _wp.unit : ''),
                              style: AppTextStyles.titleLarge.copyWith(
                                color: colors.onPrimary,
                              ),
                            ),
                            if (_wp.unit == 'g')
                              Text(
                                _wp.unit,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Non-gradient bottom section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.sp,
                  vertical: 10.sp,
                ),
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsFill.listChecks,
                      size: 15.sp,
                      color: colors.textSecondary,
                    ),
                    SizedBox(width: 6.sp),
                    Text(
                      '$totalItems item${totalItems != 1 ? 's' : ''}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    PhosphorIcon(
                      PhosphorIconsFill.backpack,
                      size: 15.sp,
                      color: colors.textSecondary,
                    ),
                    SizedBox(width: 6.sp),
                    Text(
                      capacityLiters != null
                          ? '${capacityLiters!.toStringAsFixed(0)} L'
                          : '— L',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
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
