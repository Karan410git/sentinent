import 'dart:math' as math;

import 'package:flutter/material.dart';

class WhisperDustPainter extends CustomPainter {
  const WhisperDustPainter({required this.floatingProgress});

  final double floatingProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = floatingProgress.clamp(0.0, 1.0);

    // Only appear near the highest point.
    if (progress < 0.76) {
      return;
    }

    final localProgress = ((progress - 0.76) / 0.24).clamp(0.0, 1.0);

    final fade = math.sin(localProgress * math.pi);

    final particleOrigins = <Offset>[
      Offset(size.width * 0.37, size.height * 0.72),
      Offset(size.width * 0.51, size.height * 0.74),
      Offset(size.width * 0.64, size.height * 0.70),
    ];

    for (var index = 0; index < particleOrigins.length; index++) {
      final origin = particleOrigins[index];

      final horizontalDrift =
          math.sin(localProgress * math.pi * 2 + index) * size.width * 0.008;

      final verticalRise =
          localProgress * size.height * (0.035 + index * 0.006);

      final position = Offset(
        origin.dx + horizontalDrift,
        origin.dy - verticalRise,
      );

      final opacity = (fade * (0.40 + index * 0.08)).clamp(0.0, 1.0);

      final radius = 0.9 + index * 0.25;

      final glowPaint = Paint()
        ..color = const Color(0xFFFFC85C).withValues(alpha: opacity * 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final particlePaint = Paint()
        ..color = const Color(0xFFFFDB86).withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(position, radius * 3, glowPaint);

      canvas.drawCircle(position, radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant WhisperDustPainter oldDelegate) {
    return oldDelegate.floatingProgress != floatingProgress;
  }
}
