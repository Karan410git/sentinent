import 'dart:ui';

import 'package:flutter/material.dart';

class LeatherAOPainter extends CustomPainter {
  const LeatherAOPainter({
    this.breathingProgress = 0,
  });

  final double breathingProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    /*
      When Sacheta rises during breathing, the contact darkness
      becomes slightly weaker.
    */
    final contactStrength =
        lerpDouble(1.0, 0.72, breathingProgress) ?? 1.0;

    final contactLift =
        lerpDouble(0.0, 1.8, breathingProgress) ?? 0.0;

    /*
      Contact beneath the visible page block.
      This should be narrow and close to the page edge.
    */
    final pageContact = Path()
      ..moveTo(width * 0.270, height * 0.912)
      ..lineTo(width * 0.925, height * 0.748)
      ..lineTo(width * 0.938, height * 0.775)
      ..lineTo(width * 0.292, height * 0.948)
      ..close();

    canvas.drawPath(
      pageContact.shift(
        Offset(
          width * 0.003,
          height * 0.004 + contactLift,
        ),
      ),
      Paint()
        ..color = Colors.black.withValues(
          alpha: 0.34 * contactStrength,
        )
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          2.2,
        ),
    );

    /*
      Contact beneath the lowest curved section of the spine.
    */
    final spineContact = Path()
      ..moveTo(width * 0.158, height * 0.785)
      ..quadraticBezierTo(
        width * 0.190,
        height * 0.905,
        width * 0.286,
        height * 0.956,
      )
      ..lineTo(width * 0.306, height * 0.934)
      ..quadraticBezierTo(
        width * 0.220,
        height * 0.885,
        width * 0.184,
        height * 0.775,
      )
      ..close();

    canvas.drawPath(
      spineContact.shift(
        Offset(
          width * 0.002,
          height * 0.003 + contactLift,
        ),
      ),
      Paint()
        ..color = Colors.black.withValues(
          alpha: 0.28 * contactStrength,
        )
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          2.0,
        ),
    );

    /*
      Tiny contact cue beside the lower-right corner.
      This prevents the brass corner and page block from appearing
      disconnected from the mat.
    */
    final cornerContact = Path()
      ..moveTo(width * 0.900, height * 0.736)
      ..lineTo(width * 0.955, height * 0.778)
      ..lineTo(width * 0.930, height * 0.800)
      ..lineTo(width * 0.885, height * 0.758)
      ..close();

    canvas.drawPath(
      cornerContact.shift(
        Offset(
          width * 0.003,
          height * 0.003 + contactLift,
        ),
      ),
      Paint()
        ..color = Colors.black.withValues(
          alpha: 0.24 * contactStrength,
        )
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          1.8,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant LeatherAOPainter oldDelegate) {
    return oldDelegate.breathingProgress != breathingProgress;
  }
}