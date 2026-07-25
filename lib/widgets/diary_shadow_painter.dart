import 'dart:ui';

import 'package:flutter/material.dart';

class DiaryShadowPainter extends CustomPainter {
  const DiaryShadowPainter({
    this.breathingProgress = 0,
  });

  final double breathingProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    /*
      Approximate visible silhouette of Sacheta.

      These points follow the diary's perspective inside the PNG.
    */
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

    final breathingLift =
        lerpDouble(0, 3.5, breathingProgress) ?? 0;

    /*
      DIRECTIONAL CAST SHADOW

      The candle is above-left, therefore the visible shadow travels
      primarily right and slightly downward.
    */

    _drawDirectionalShadow(
      canvas: canvas,
      sourcePath: diaryShape,
      offset: Offset(
        width * 0.095,
        height * 0.026 + breathingLift,
      ),
      opacity: 0.08,
      blurSigma: 25,
      stretchX: 1.08,
      stretchY: 1.015,
    );

    _drawDirectionalShadow(
      canvas: canvas,
      sourcePath: diaryShape,
      offset: Offset(
        width * 0.064,
        height * 0.018 + breathingLift * 0.7,
      ),
      opacity: 0.15,
      blurSigma: 13,
      stretchX: 1.045,
      stretchY: 1.008,
    );

    /*
      RIGHT-SIDE CORE SHADOW

      This begins close to Sacheta's right edge and fades outward.
      It avoids placing unnecessary darkness beneath the centre.
    */
    final rightSideShadow = Path()
      ..moveTo(width * 0.765, height * 0.055)
      ..lineTo(width * 0.955, height * 0.785)
      ..lineTo(width * 0.885, height * 0.81)
      ..lineTo(width * 0.705, height * 0.09)
      ..close();

    canvas.drawPath(
      rightSideShadow.shift(
        Offset(
          width * 0.038,
          height * 0.014 + breathingLift * 0.5,
        ),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          7.5,
        ),
    );

    /*
      THIN CONTACT SHADOW

      Only the lower and right touching edges receive a tight shadow.
      There is deliberately no large contact shadow beneath the centre.
    */
    final lowerContact = Path()
      ..moveTo(width * 0.275, height * 0.918)
      ..lineTo(width * 0.925, height * 0.755)
      ..lineTo(width * 0.945, height * 0.79)
      ..lineTo(width * 0.29, height * 0.965)
      ..close();

    canvas.drawPath(
      lowerContact.shift(
        Offset(
          width * 0.006,
          height * 0.004 + breathingLift * 0.12,
        ),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          2.8,
        ),
    );

    final rightContact = Path()
      ..moveTo(width * 0.765, height * 0.055)
      ..lineTo(width * 0.955, height * 0.785)
      ..lineTo(width * 0.928, height * 0.793)
      ..lineTo(width * 0.742, height * 0.066)
      ..close();

    canvas.drawPath(
      rightContact.shift(
        Offset(
          width * 0.005,
          height * 0.003,
        ),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.50)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          2.5,
        ),
    );

    /*
      SMALL SPINE CONTACT

      A restrained shadow remains near the bottom of the curved spine.
      It should not extend beneath the whole left side.
    */
    final spineContact = Path()
      ..moveTo(width * 0.15, height * 0.72)
      ..quadraticBezierTo(
        width * 0.17,
        height * 0.89,
        width * 0.285,
        height * 0.96,
      )
      ..lineTo(width * 0.305, height * 0.935)
      ..quadraticBezierTo(
        width * 0.205,
        height * 0.865,
        width * 0.175,
        height * 0.71,
      )
      ..close();

    canvas.drawPath(
      spineContact.shift(
        const Offset(2, 2),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          2.6,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant DiaryShadowPainter oldDelegate) {
    return oldDelegate.breathingProgress != breathingProgress;
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

  canvas.clipRect(
    Rect.fromLTRB(
      bounds.left + bounds.width * 0.42,
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
}