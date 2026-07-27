import 'dart:ui';

import 'package:flutter/material.dart';

class DiaryCastShadowPainter extends CustomPainter {
  const DiaryCastShadowPainter({required this.floatingProgress});

  final double floatingProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = floatingProgress.clamp(0.0, 1.0);

    final shadowOpacity = lerpDouble(0.28, 0.13, progress) ?? 0.24;

    final shadowBlur = lerpDouble(10.0, 18.0, progress) ?? 10.0;

    final horizontalSpread = lerpDouble(1.0, 1.08, progress) ?? 1.0;

    final verticalSpread = lerpDouble(1.0, 1.05, progress) ?? 1.0;

    final verticalOffset = lerpDouble(4.0, 6.0, progress) ?? 4.0;

    final shadowRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.55 + verticalOffset),
      width: size.width * 0.82 * horizontalSpread,
      height: size.height * 0.67 * verticalSpread,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        shadowRect,
        Radius.circular(size.shortestSide * 0.035),
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DiaryCastShadowPainter oldDelegate) {
    return oldDelegate.floatingProgress != floatingProgress;
  }
}
