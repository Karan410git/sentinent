import 'dart:ui';

import 'package:flutter/material.dart';

import 'diary_shadow_painter.dart';

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
        // Directional shadow cast away from the upper-left candle.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: DiaryShadowPainter(
                breathingProgress: breathingProgress,
              ),
            ),
          ),
        ),

        // Sacheta itself.
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 0.18,
            sigmaY: 0.18,
          ),
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              // Slightly softened contrast and warmer integration.
              0.975, 0.010, 0.005, 0, 1.2,
              0.006, 0.972, 0.006, 0, 1.0,
              0.002, 0.008, 0.962, 0, 0.5,
              0,     0,     0,     1, 0,
            ]),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),

        // Very restrained candlelight wrap.
        const Positioned.fill(
          child: IgnorePointer(
            child: _CandleEdgeWrap(),
          ),
        ),
      ],
    );
  }
}

class _CandleEdgeWrap extends StatelessWidget {
  const _CandleEdgeWrap();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.055,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1.0, -0.9),
            end: Alignment(0.9, 1.0),
            colors: [
              Color(0xFFFFD59A),
              Color(0x66E19A54),
              Colors.transparent,
              Color(0x22000000),
            ],
            stops: [
              0.00,
              0.22,
              0.62,
              1.00,
            ],
          ),
        ),
      ),
    );
  }
}