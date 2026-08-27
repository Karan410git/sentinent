import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Widget wrapper for [AmbientDustPainter].
///
/// Positioned above the diary in the scene stack so the dust
/// appears to float in the candle-lit air in front of the diary.
class AmbientDust extends StatelessWidget {
  const AmbientDust({super.key, required this.elapsed});

  final double elapsed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(painter: AmbientDustPainter(elapsed: elapsed)),
        ),
      ),
    );
  }
}

/// Renders extremely subtle, warm atmospheric dust that drifts
/// slowly through the candle-lit study.
///
/// This is kept deliberately separate from [GoldDustPainter].
/// Ambient dust is always present and nearly invisible; it exists
/// to give the candlelight something to illuminate. Gold dust is
/// a rare, attention-grabbing magical event.
class AmbientDustPainter extends CustomPainter {
  const AmbientDustPainter({required this.elapsed});

  /// Continuous time value (seconds) driving the drift animation.
  final double elapsed;

  static final List<_DustParticle> _particles = _DustParticle.generate(
    100,
    seed: 20240826,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE0D4BF);

    for (final p in _particles) {
      // Two independent sine waves give each particle a gentle,
      // non-circular drift — never mechanical or looping-looking.
      final driftX = math.sin(elapsed * p.freqX + p.phaseX);
      final driftY = math.sin(elapsed * p.freqY + p.phaseY);

      final x = (p.baseX + p.driftAmplitude * driftX) * size.width;
      final y = (p.baseY + p.driftAmplitude * driftY) * size.height;

      // Subtle opacity modulation on a subset of particles so
      // the eye never quite settles on a fixed pattern.
      var opacity = p.opacity;
      if (p.twinkleAmp > 0) {
        opacity *=
            1.0 +
            p.twinkleAmp * math.sin(elapsed * p.twinkleFreq + p.twinklePhase);
      }

      paint.color = const Color(0xFFE0D4BF).withValues(alpha: opacity);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, p.blur);

      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AmbientDustPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed;
  }
}

class _DustParticle {
  const _DustParticle({
    required this.baseX,
    required this.baseY,
    required this.driftAmplitude,
    required this.freqX,
    required this.freqY,
    required this.phaseX,
    required this.phaseY,
    required this.radius,
    required this.blur,
    required this.opacity,
    required this.twinkleAmp,
    required this.twinkleFreq,
    required this.twinklePhase,
  });

  final double baseX;
  final double baseY;
  final double driftAmplitude;
  final double freqX;
  final double freqY;
  final double phaseX;
  final double phaseY;
  final double radius;
  final double blur;
  final double opacity;
  final double twinkleAmp;
  final double twinkleFreq;
  final double twinklePhase;

  static List<_DustParticle> generate(int count, {required int seed}) {
    final rng = math.Random(seed);

    return List.generate(count, (_) {
      // Bias toward the upper portion of the screen where candlelight
      // reaches most strongly — dust in deep shadow stays hidden.
      final baseY = 0.04 + math.pow(rng.nextDouble(), 1.8).toDouble() * 0.92;

      // ~15 % of particles have a slow, subtle twinkle.
      final hasTwinkle = rng.nextDouble() < 0.15;

      return _DustParticle(
        baseX: 0.03 + rng.nextDouble() * 0.94,
        baseY: baseY,
        driftAmplitude: 0.018 + rng.nextDouble() * 0.022,
        freqX: 0.03 + rng.nextDouble() * 0.06,
        freqY: 0.025 + rng.nextDouble() * 0.08,
        phaseX: rng.nextDouble() * math.pi * 2,
        phaseY: rng.nextDouble() * math.pi * 2,
        radius: 0.4 + rng.nextDouble() * 1.1,
        blur: 0.8 + rng.nextDouble() * 1.3,
        opacity: 0.04 + rng.nextDouble() * 0.07,
        twinkleAmp: hasTwinkle ? 0.15 + rng.nextDouble() * 0.15 : 0,
        twinkleFreq: hasTwinkle ? 0.01 + rng.nextDouble() * 0.03 : 0,
        twinklePhase: hasTwinkle ? rng.nextDouble() * math.pi * 2 : 0,
      );
    });
  }
}
