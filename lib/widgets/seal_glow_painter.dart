import 'dart:math' as math;

import 'package:flutter/material.dart';

class SealGlowPainter extends CustomPainter {
  const SealGlowPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final value = progress.clamp(0.0, 1.0);

    // Gradually appears, peaks, then gently settles.
    final envelope = math.sin(value * math.pi);

    // Approximate position of Sacheta's circular emblem.
    final center = Offset(
      size.width * 0.49,
      size.height * 0.33,
    );

    final radius = size.shortestSide *
        (0.09 + envelope * 0.045);

    final glowShader = RadialGradient(
      colors: [
        const Color(0xFFFFE3A0).withValues(
          alpha: envelope * 0.52,
        ),
        const Color(0xFFFFBD4A).withValues(
          alpha: envelope * 0.25,
        ),
        const Color(0xFFE58B24).withValues(
          alpha: envelope * 0.08,
        ),
        Colors.transparent,
      ],
      stops: const [
        0.0,
        0.28,
        0.62,
        1.0,
      ],
    ).createShader(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = glowShader
        ..blendMode = BlendMode.screen,
    );

    // Tight highlight directly on the emblem.
    canvas.drawCircle(
      center,
      size.shortestSide * 0.042,
      Paint()
        ..color = const Color(0xFFFFD77A).withValues(
          alpha: envelope * 0.13,
        )
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          5,
        )
        ..blendMode = BlendMode.screen,
    );
  }

  @override
  bool shouldRepaint(
    covariant SealGlowPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}