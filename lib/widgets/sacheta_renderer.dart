import 'dart:ui';

import 'package:flutter/material.dart';

import 'diary_cast_shadow_painter.dart';
import 'gold_dust_painter.dart';
import 'leather_ao_painter.dart';
import 'whisper_dust_painter.dart';
import 'seal_glow_painter.dart';
import 'seal_dust_painter.dart';

class SachetaRenderer extends StatelessWidget {
  const SachetaRenderer({
    super.key,
    required this.assetPath,
    this.floatingProgress = 0,
    this.goldDustProgress = 0,
    this.sealGlowProgress = 0,
    this.sealDustProgress = 0,
  });

  final String assetPath;
  final double floatingProgress;
  final double goldDustProgress;
  final double sealGlowProgress;
  final double sealDustProgress;

  @override
  Widget build(BuildContext context) {
    final progress = floatingProgress.clamp(0.0, 1.0);

    final floatOffset = lerpDouble(0.0, -4.3, progress) ?? 0.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: DiaryCastShadowPainter(floatingProgress: progress),
            ),
          ),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: LeatherAOPainter(floatingProgress: progress),
            ),
          ),
        ),

        Transform.translate(
          offset: Offset(0, floatOffset),
          child: RepaintBoundary(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.975,
                0.010,
                0.005,
                0,
                1.2,
                0.006,
                0.972,
                0.006,
                0,
                1.0,
                0.002,
                0.008,
                0.962,
                0,
                0.5,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      Positioned.fill(
  child: IgnorePointer(
    child: CustomPaint(
      painter: SealDustPainter(
        progress: sealDustProgress,
      ),
    ),
  ),
),  
      Positioned.fill(
  child: IgnorePointer(
    child: CustomPaint(
      painter: SealGlowPainter(
        progress: sealGlowProgress,
      ),
    ),
  ),
),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: WhisperDustPainter(floatingProgress: progress),
            ),
          ),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: GoldDustPainter(progress: goldDustProgress),
            ),
          ),
        ),
      ],
    );
  }
}
