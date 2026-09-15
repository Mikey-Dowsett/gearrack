import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ui_constants.dart';

/// Shared shell for add/edit forms (gear, pack, trip).
/// Plain AppBar + padded scroll body + primary bottom-sheet save button.
/// Replaces three copy-pasted Scaffold/bottomSheet blocks.
class FormShell extends StatelessWidget {
  final String title;
  final String saveLabel;
  final VoidCallback? onSave;
  final bool isSaving;
  final Widget child;

  const FormShell({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.onSave,
    required this.child,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onBackground),
        ),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.sp),
        child: child,
      ),
      bottomSheet: SafeArea(
        left: false,
        right: false,
        bottom: true,
        child: Container(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 8.sp),
          color: colors.background,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    minimumSize: Size.fromHeight(56.sp),
                    padding: EdgeInsets.symmetric(vertical: 0.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        UiConstants.buttonRadius.sp,
                      ),
                    ),
                  ),
                  onPressed: isSaving ? null : onSave,
                  child: isSaving
                      ? SizedBox(
                          height: 24.sp,
                          width: 24.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.sp,
                            color: colors.onPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(
                              PhosphorIconsFill.check,
                              color: colors.onPrimary,
                              size: 25.sp,
                            ),
                            SizedBox(width: 8.sp),
                            Text(
                              saveLabel,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: colors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim green context hero for forms — same construction as the
/// gear detail hero badge row, single-line + ellipsis throughout.
class FormHero extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String? spec;

  const FormHero({
    super.key,
    required this.icon,
    required this.label,
    required this.title,
    this.spec,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      color: colors.primary,
      padding: EdgeInsets.symmetric(vertical: 14.sp, horizontal: 16.sp),
      child: Row(
        children: [
          Container(
            width: 25.sp,
            height: 25.sp,
            decoration: BoxDecoration(
              color: colors.primaryMuted,
              borderRadius: BorderRadius.all(
                Radius.circular(UiConstants.compactCardRadius.sp),
              ),
            ),
            alignment: Alignment.center,
            child: PhosphorIcon(icon, size: 15.sp, color: colors.onPrimary),
          ),
          SizedBox(width: 8.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.onPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: AppTextStyles.specMedium.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (spec != null)
                  Text(
                    spec!,
                    style: AppTextStyles.specSmall.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
