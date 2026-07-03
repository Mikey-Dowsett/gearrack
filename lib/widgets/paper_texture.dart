import 'dart:math';
import 'package:flutter/material.dart';

/// Subtle paper texture overlay using fine fibers and a warm age gradient.
///
/// **Fiber layer** — hundreds of fine lines at random positions/angles
/// mimicking paper fibres. **Age gradient** — a soft radial warm-brown
/// tint from center → edges, like vintage paper yellowing.
///
/// Applied via [MaterialApp.builder] so it sits over every page without
/// touching individual scaffold implementations.
class PaperTexture extends StatelessWidget {
  const PaperTexture({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: const _PaperPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // fixed seed → stable texture

    // --- 1. Fiber layer (fine lines, like paper fibres) ---
    final fiberCount = (size.width * size.height / 180).floor().clamp(800, 8000);
    final fiberPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    for (int i = 0; i < fiberCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final length = rng.nextDouble() * 40 + 8;
      final angle = rng.nextDouble() * pi;
      final alpha = (rng.nextDouble() * 2 + 1).round().clamp(1, 3);

      fiberPaint.color = Color.fromARGB(alpha, 60, 45, 30);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + cos(angle) * length, y + sin(angle) * length),
        fiberPaint,
      );
    }

    // --- 2. Age gradient (warm vignette) ---
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.7;

    final gradient = RadialGradient(
      center: const Alignment(0.0, 0.0),
      radius: 1.0,
      colors: const [
        Color(0x00000000),
        Color(0x08000000),
        Color(0x12A08050),
      ],
      stops: const [0.5, 0.85, 1.0],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.multiply;

    canvas.drawRect(Offset.zero & size, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
