import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
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
  final IconData? iconData;
  final Color? iconColor;
  final int? count;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;

  const PatchChip({
    super.key,
    required this.label,
    this.iconKey,
    this.iconData,
    this.iconColor,
    this.count,
    required this.selected,
    required this.onSelected,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final fill = selectedColor ?? colors.primary;
    final fg = selected ? colors.onPrimary : colors.onSurface;
    final resolvedIcon = iconData ??
        (iconKey != null ? IconRegistry.resolve(iconKey!) : null);
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resolvedIcon != null)
            PhosphorIcon(
              resolvedIcon,
              size: UiConstants.iconSmall.sp,
              color: selected ? fg : (iconColor ?? colors.textSecondary),
            ),
          if (resolvedIcon != null) SizedBox(width: 6.sp),
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
      selectedColor: fill,
      backgroundColor: colors.surface,
      // Dashed-stitch illusion: solid outer outline (theme) + tighter radius.
      // True dashed stroke lives on SectionHeader dividers to keep cost low.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiConstants.buttonRadius.sp),
        side: BorderSide(
          color: selected ? fill : colors.border,
          width: UiConstants.borderWidth,
        ),
      ),
    );
  }
}
