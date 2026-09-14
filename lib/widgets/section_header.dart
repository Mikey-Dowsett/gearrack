import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Trailhead section header: Fraunces title + 4px tertiary accent bar
/// + mono spec count. Replaces ad-hoc Row(title • count) copies.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? spec;
  final FaIconData? icon;
  final Color? iconColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.spec,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4.sp,
          height: 18.sp,
          decoration: BoxDecoration(
            color: colors.tertiary,
            borderRadius: BorderRadius.circular(1.sp),
          ),
        ),
        SizedBox(width: 8.sp),
        if (icon != null) ...[
          FaIcon(
            icon!,
            size: 14.sp,
            color: iconColor ?? colors.textSecondary,
          ),
          SizedBox(width: 6.sp),
        ],
        Flexible(
          child: Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(color: colors.onBackground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (spec != null) ...[
          SizedBox(width: 8.sp),
          Flexible(
            child: Text(
              spec!.toUpperCase(),
              style: AppTextStyles.specSmall.copyWith(
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// Faint topo-contour backdrop for list headers. Cheap CustomPaint,
/// a few wavy polylines in border color at low alpha — no images.
class TopoBackdrop extends StatelessWidget {
  final Widget child;
  const TopoBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return CustomPaint(
      painter: _TopoPainter(color: colors.borderStrong.withValues(alpha: 0.35)),
      child: child,
    );
  }
}

class _TopoPainter extends CustomPainter {
  final Color color;
  _TopoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    // 4 contour bands drifting across the header
    for (int b = 0; b < 4; b++) {
      final y0 = size.height * (0.15 + b * 0.22);
      final path = Path()..moveTo(-20, y0);
      for (double x = -20; x < size.width + 20; x += 16) {
        final wobble = (b.isEven ? 1 : -1) * 6 * (0.5 + 0.5 * (x % 48) / 48);
        path.lineTo(x, y0 + wobble * (b + 1) / 3);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
