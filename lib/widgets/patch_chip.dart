import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ui_constants.dart';
import '../utils/icon_registry.dart';

/// Sewn-patch filter chip: squarer than a pill, uppercase mono label,
/// icon in category color, count in a small badge.
/// Selected = forest fill with cream text; unselected = surface.
class PatchChip extends StatelessWidget {
  final String label;
  final String? iconKey;
  final Color? iconColor;
  final int? count;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const PatchChip({
    super.key,
    required this.label,
    this.iconKey,
    this.iconColor,
    this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final fg = selected ? colors.onPrimary : colors.onSurface;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconKey != null)
            FaIcon(
              IconRegistry.resolve(iconKey!),
              size: UiConstants.iconSmall.sp,
              color: selected ? fg : (iconColor ?? colors.textSecondary),
            ),
          if (iconKey != null) SizedBox(width: 6.sp),
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.specSmall.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: 6.sp),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 1.sp),
              decoration: BoxDecoration(
                color: selected
                    ? colors.onPrimary.withValues(alpha: 0.2)
                    : colors.surfaceRaised,
                borderRadius: BorderRadius.circular(3.sp),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.specSmall.copyWith(color: fg),
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: colors.primary,
      backgroundColor: colors.surface,
      // Dashed-stitch illusion: solid outer outline (theme) + tighter radius.
      // True dashed stroke lives on SectionHeader dividers to keep cost low.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiConstants.buttonRadius.sp),
        side: BorderSide(
          color: selected ? colors.primary : colors.border,
          width: UiConstants.borderWidth,
        ),
      ),
    );
  }
}
