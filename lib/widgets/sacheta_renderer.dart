import 'dart:ui';

import 'package:flutter/material.dart';

import 'diary_cast_shadow_painter.dart';
import 'leather_ao_painter.dart';

class SachetaRenderer extends StatelessWidget {
  const SachetaRenderer({
    super.key,
    required this.assetPath,
    this.breathingProgress = 0,
  });

  final String assetPath;
  final double breathingProgress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: DiaryCastShadowPainter(
                breathingProgress: breathingProgress,
              ),
            ),
          ),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: LeatherAOPainter(
                breathingProgress: breathingProgress,
              ),
            ),
          ),
        ),

        Transform.translate(
          offset: Offset(
            0,
            lerpDouble(0, -2.0, breathingProgress) ?? 0,
          ),
          child: Transform.scale(
            scale:
                lerpDouble(1.0, 1.003, breathingProgress) ?? 1,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 0.18,
                sigmaY: 0.18,
              ),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.975, 0.010, 0.005, 0, 1.2,
                  0.006, 0.972, 0.006, 0, 1.0,
                  0.002, 0.008, 0.962, 0, 0.5,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}