import 'dart:math' as math;

import 'package:flutter/material.dart';

class SealDustPainter extends CustomPainter {
  const SealDustPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.clamp(0.0, 1.0);

    if (value <= 0 || value >= 1) {
      return;
    }

    // Same emblem coordinates you confirmed on the phone.
    final sealCenter = Offset(size.width * 0.49, size.height * 0.33);

    const particleCount = 26;

    for (var index = 0; index < particleCount; index++) {
      final seed = index / particleCount;
      final angle = seed * math.pi * 2;

      // Irregular starting distance around Sacheta.
      final radiusX = size.width * (0.22 + 0.035 * math.sin(index * 1.71));

      final radiusY = size.height * (0.25 + 0.030 * math.cos(index * 1.43));

      final start = Offset(
        sealCenter.dx + math.cos(angle) * radiusX,
        sealCenter.dy + math.sin(angle) * radiusY,
      );

      // Slight curved movement instead of perfectly straight lines.
      final curveOffset = Offset(
        math.sin(value * math.pi) *
            math.cos(angle + index) *
            size.width *
            0.035,
        math.sin(value * math.pi) *
            math.sin(angle + index) *
            size.height *
            0.025,
      );

      final position =
          Offset.lerp(start, sealCenter, Curves.easeInCubic.transform(value))! +
          curveOffset;

      // Fade in, remain visible, then disappear into the emblem.
      final fadeIn = Curves.easeOut.transform((value / 0.22).clamp(0.0, 1.0));

      final fadeOut =
          1 - Curves.easeIn.transform(((value - 0.72) / 0.28).clamp(0.0, 1.0));

      final twinkle = 0.65 + 0.35 * math.sin(value * math.pi * 8 + index);

      final opacity = (fadeIn * fadeOut * twinkle * 0.94).clamp(0.0, 1.0);

      final particleRadius = 0.8 + (index % 4) * 0.32;

      canvas.drawCircle(
        position,
        particleRadius * 3,
        Paint()
          ..color = const Color(0xFFFFB93D).withValues(alpha: opacity * 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      canvas.drawCircle(
        position,
        particleRadius,
        Paint()
          ..color = const Color(0xFFFFDF8B).withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }

    // Final small flash as all particles enter the emblem.
    if (value > 0.78) {
      final flashProgress = ((value - 0.78) / 0.22).clamp(0.0, 1.0);

      final flashEnvelope = math.sin(flashProgress * math.pi);

      canvas.drawCircle(
        sealCenter,
        size.shortestSide * (0.035 + flashEnvelope * 0.025),
        Paint()
          ..color = const Color(
            0xFFFFD773,
          ).withValues(alpha: flashEnvelope * 0.34)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..blendMode = BlendMode.screen,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SealDustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
