import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../animations/entrance_animation.dart';

class CandleGlow extends StatelessWidget {
  final EntranceAnimation entrance;

  const CandleGlow({super.key, required this.entrance});

  @override
  Widget build(BuildContext context) {
    /*
      Animation phases:

      0.00 – 0.12  Tiny ember
      0.12 – 0.78  Candlelight spreads
      0.78 – 0.92  Room settles
      0.92 – 1.00  Gentle final flicker
    */

    final emberProgress = entrance.ember.value;

    final revealProgress = entrance.reveal.value;

    final warmthProgress = entrance.warmth.value;

    final settleProgress = entrance.settle.value;

    final flickerProgress = entrance.flicker.value;

    final flicker = math.sin(flickerProgress * math.pi) * 0.045;

    final revealRadius = lerpDouble(
      40,
      1150,
      Curves.easeInOutCubic.transform(revealProgress),
    )!;

    final darkness = lerpDouble(0.94, 0.05, settleProgress)!;

    final warmGlowOpacity = lerpDouble(0.00, 0.22, warmthProgress)! + flicker;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          /*
            This layer creates darkness and gradually cuts an
            oval-shaped opening through it from the candle.
          */
          CustomPaint(
            painter: _CandleRevealPainter(
              radius: revealRadius,
              darkness: darkness,
              emberStrength: emberProgress,
            ),
          ),

          /*
            Warm amber light placed over the revealed scene.
          */
          Opacity(
            opacity: warmGlowOpacity.clamp(0.0, 1.0),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.76, -0.72),
                  radius: 1.25,
                  colors: [
                    Color(0x88FFE2A0),
                    Color(0x44FFC561),
                    Color(0x18FFAA3D),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.32, 0.68, 1.0],
                ),
              ),
            ),
          ),

          /*
            A permanent, subtle vignette keeps the final scene
            intimate instead of completely flat and bright.
          */
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.05),
                radius: 1.08,
                colors: [
                  Colors.transparent,
                  Color(0x08000000),
                  Color(0x28000000),
                ],
                stops: [0.55, 0.82, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandleRevealPainter extends CustomPainter {
  final double radius;
  final double darkness;
  final double emberStrength;

  const _CandleRevealPainter({
    required this.radius,
    required this.darkness,
    required this.emberStrength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    /*
      Candle position. We use coordinates instead of Alignment
      because this painter works directly with the canvas.
    */
    final candleCenter = Offset(size.width * 0.12, size.height * 0.14);

    canvas.saveLayer(bounds, Paint());

    /*
      Paint the dark room first.
    */
    canvas.drawRect(
      bounds,
      Paint()..color = Colors.black.withValues(alpha: darkness),
    );

    /*
      Scale the canvas so the light is slightly oval instead of
      looking like a perfectly circular flashlight.
    */
    canvas.save();

    canvas.translate(candleCenter.dx, candleCenter.dy);

    canvas.scale(1.15, 0.88);

    canvas.translate(-candleCenter.dx, -candleCenter.dy);

    final revealShader = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.96),
        Colors.white.withValues(alpha: 0.82),
        Colors.white.withValues(alpha: 0.40),
        Colors.transparent,
      ],
      stops: const [0.0, 0.30, 0.70, 1.0],
    ).createShader(Rect.fromCircle(center: candleCenter, radius: radius));

    canvas.drawCircle(
      candleCenter,
      radius,
      Paint()
        ..shader = revealShader
        ..blendMode = BlendMode.dstOut,
    );

    canvas.restore();

    /*
      Before the full reveal begins, this creates a very small
      ember-like opening around the candle.
    */
    if (emberStrength > 0 && radius < 200) {
      final emberRadius = lerpDouble(8, 42, emberStrength)!;

      final emberShader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.30),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: candleCenter, radius: emberRadius),
          );

      canvas.drawCircle(
        candleCenter,
        emberRadius,
        Paint()
          ..shader = emberShader
          ..blendMode = BlendMode.dstOut,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CandleRevealPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.darkness != darkness ||
        oldDelegate.emberStrength != emberStrength;
  }
}
