import 'dart:ui';

import 'package:flutter/material.dart';

class LeatherAOPainter extends CustomPainter {
  const LeatherAOPainter({required this.floatingProgress});

  final double floatingProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = floatingProgress.clamp(0.0, 1.0);

    final aoOpacity = lerpDouble(0.27, 0.06, progress) ?? 0.18;

    final aoBlur = lerpDouble(6.0, 12.0, progress) ?? 6.0;

    final aoWidth = lerpDouble(0.76, 0.83, progress) ?? 0.77;

    final aoHeight = lerpDouble(0.60, 0.66, progress) ?? 0.61;

    final contactRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.54),
      width: size.width * aoWidth,
      height: size.height * aoHeight,
    );

    final contactPaint = Paint()
      ..color = Colors.black.withValues(alpha: aoOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, aoBlur);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        contactRect,
        Radius.circular(size.shortestSide * 0.03),
      ),
      contactPaint,
    );
  }

  @override
  bool shouldRepaint(covariant LeatherAOPainter oldDelegate) {
    return oldDelegate.floatingProgress != floatingProgress;
  }
}
