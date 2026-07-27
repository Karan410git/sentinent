import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoldDustPainter extends CustomPainter {
  const GoldDustPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }

    final center = Offset(size.width * 0.52, size.height * 0.50);

    // Fade in, remain briefly, then fade away.
    final envelope = math.sin(progress * math.pi);

    const particleCount = 30;

    for (var index = 0; index < particleCount; index++) {
      final seed = index / particleCount;
      final angle = seed * math.pi * 2;

      // Slightly irregular orbit so it does not look mechanical.
      final phase = progress * 1.35 + seed;
      final orbitX = size.width * (0.31 + 0.025 * math.sin(index * 1.7));
      final orbitY = size.height * (0.36 + 0.020 * math.cos(index * 1.3));

      final x = center.dx + math.cos(angle + phase) * orbitX;

      final y =
          center.dy +
          math.sin(angle + phase) * orbitY -
          progress * size.height * 0.045;

      final twinkle = 0.55 + 0.45 * math.sin(progress * math.pi * 6 + index);

      final opacity = (envelope * twinkle * 0.72).clamp(0.0, 1.0);

      final radius = 0.8 + (index % 4) * 0.35;

      final particlePaint = Paint()
        ..color = const Color(0xFFFFD77A).withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(Offset(x, y), radius, particlePaint);

      // A few particles receive a very soft outer halo.
      if (index % 5 == 0) {
        canvas.drawCircle(
          Offset(x, y),
          radius * 2.6,
          Paint()
            ..color = const Color(0xFFFFC44F).withValues(alpha: opacity * 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GoldDustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
