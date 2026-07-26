import 'dart:ui';

import 'package:flutter/material.dart';

class DiaryCastShadowPainter extends CustomPainter {
  const DiaryCastShadowPainter({
    this.breathingProgress = 0,
  });

  final double breathingProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final diaryShape = Path()
      ..moveTo(width * 0.095, height * 0.205)
      ..lineTo(width * 0.765, height * 0.045)
      ..lineTo(width * 0.955, height * 0.785)
      ..lineTo(width * 0.285, height * 0.965)
      ..quadraticBezierTo(
        width * 0.185,
        height * 0.955,
        width * 0.155,
        height * 0.875,
      )
      ..lineTo(width * 0.075, height * 0.29)
      ..quadraticBezierTo(
        width * 0.065,
        height * 0.235,
        width * 0.095,
        height * 0.205,
      )
      ..close();

    /*
      As Sacheta rises, the cast shadow moves slightly farther away
      and becomes a little softer.
    */
    final shadowDistance =
        lerpDouble(0.0, 4.0, breathingProgress) ?? 0.0;

    final blurSigma =
        lerpDouble(14.0, 17.0, breathingProgress) ?? 14.0;

    final opacity =
        lerpDouble(0.16, 0.12, breathingProgress) ?? 0.16;

    _drawDirectionalShadow(
      canvas: canvas,
      sourcePath: diaryShape,
      offset: Offset(
        width * 0.075 + shadowDistance,
        height * 0.014 + shadowDistance * 0.35,
      ),
      opacity: opacity,
      blurSigma: blurSigma,
      stretchX: 1.065,
      stretchY: 1.006,
    );
  }

  void _drawDirectionalShadow({
    required Canvas canvas,
    required Path sourcePath,
    required Offset offset,
    required double opacity,
    required double blurSigma,
    required double stretchX,
    required double stretchY,
  }) {
    final bounds = sourcePath.getBounds();
    final center = bounds.center;

    canvas.save();

    canvas.translate(
      center.dx + offset.dx,
      center.dy + offset.dy,
    );

    canvas.scale(
      stretchX,
      stretchY,
    );

    canvas.translate(
      -center.dx,
      -center.dy,
    );

    /*
      Keep the broad cast shadow primarily on the side opposite
      the upper-left candle.
    */
    canvas.clipRect(
      Rect.fromLTRB(
        bounds.left + bounds.width * 0.48,
        bounds.top - blurSigma * 3,
        bounds.right + offset.dx + blurSigma * 4,
        bounds.bottom + offset.dy + blurSigma * 4,
      ),
    );

    canvas.drawPath(
      sourcePath,
      Paint()
        ..color = Colors.black.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          blurSigma,
        ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant DiaryCastShadowPainter oldDelegate,
  ) {
    return oldDelegate.breathingProgress != breathingProgress;
  }
}