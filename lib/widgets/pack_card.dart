import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../models/pack.dart';

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

    return Padding(
      padding: EdgeInsets.only(
        right: 8.0.w,
        left: 8.0.w,
        top: 4.0.h,
        bottom: 4.0.h,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Card.filled(
          color: colors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0.sp),
            side: BorderSide(color: colors.border, width: 2.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.sp),
                    topRight: Radius.circular(10.sp),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.accent],
                  ),
                ),
                padding: EdgeInsets.all(14.sp),
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
                          ),
                          if (pack.description != null &&
                              pack.description!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 4.sp),
                              child: Text(
                                pack.description!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                            ),
                          if (bagName != null && bagName!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 4.sp),
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.suitcase,
                                    size: 12.sp,
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  SizedBox(width: 4.sp),
                                  Text(
                                    bagName!,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: colors.onPrimary.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          totalWeightGrams >= 1000
                              ? '${(totalWeightGrams / 1000).toStringAsFixed(1)} kg'
                              : '${totalWeightGrams.toStringAsFixed(0)} g',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                        Text(
                          totalWeightGrams >= 1000 ? '' : 'g',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: colors.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Non-gradient bottom section
              Padding(
                padding: EdgeInsets.all(12.sp),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.box,
                      size: 14.sp,
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
                    FaIcon(
                      FontAwesomeIcons.boxOpen,
                      size: 14.sp,
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
