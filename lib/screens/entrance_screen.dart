import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/session_service.dart';

/// The first screen the user sees — dark, atmospheric, poetic.
/// "The pages remember."
class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _dustController;
  bool _entering = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _dustController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dustController.dispose();
    super.dispose();
  }

  Future<void> _handleEntry() async {
    if (_entering) return;
    setState(() => _entering = true);

    await SessionService.instance.enterTemporarySession();
    if (!mounted) return;

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0806),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _fadeController,
            curve: const Interval(0.0, 0.6),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle radial vignette
              const _Vignette(),

              // Floating dust particles
              AnimatedBuilder(
                animation: _dustController,
                builder: (context, _) => CustomPaint(
                  painter: _DustPainter(progress: _dustController.value),
                  size: Size.infinite,
                ),
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // Poetic text
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _fadeController,
                          curve: const Interval(0.3, 0.8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '"The pages remember."',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 26,
                                color: const Color(0xFFD4C5A9),
                                fontWeight: FontWeight.w300,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Do you wish to enter?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 17,
                                color: const Color(
                                  0xFFD4C5A9,
                                ).withValues(alpha: 0.5),
                                fontWeight: FontWeight.w300,
                                height: 1.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Buttons
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _fadeController,
                          curve: const Interval(0.5, 1.0),
                        ),
                        child: Column(
                          children: [
                            _EntranceButton(
                              label: 'CONTINUE WITH GOOGLE',
                              onTap: _handleEntry,
                              isPrimary: true,
                            ),
                            const SizedBox(height: 14),
                            _EntranceButton(
                              label: 'SIGN IN',
                              onTap: _handleEntry,
                            ),
                            const SizedBox(height: 14),
                            _EntranceButton(
                              label: 'CREATE ACCOUNT',
                              onTap: _handleEntry,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark radial vignette overlay.
class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.2,
          colors: [
            const Color(0xFF1A120A).withValues(alpha: 0.4),
            const Color(0xFF0A0806),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

/// A single entrance button with parchment-like styling.
class _EntranceButton extends StatefulWidget {
  const _EntranceButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  State<_EntranceButton> createState() => _EntranceButtonState();
}

class _EntranceButtonState extends State<_EntranceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isPrimary
        ? const Color(0xFFB8943E).withValues(alpha: 0.5)
        : const Color(0xFFD4C5A9).withValues(alpha: 0.15);
    final textColor = widget.isPrimary
        ? const Color(0xFFD4C5A9)
        : const Color(0xFFD4C5A9).withValues(alpha: 0.6);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _pressScale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? const Color(0xFF1A120A).withValues(alpha: 0.6)
                : const Color(0xFF0F0B08).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle floating dust particles painted over the dark background.
class _DustPainter extends CustomPainter {
  _DustPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(42);

    for (var i = 0; i < 35; i++) {
      final seed = rng.nextDouble();
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + seed * 0.7;

      final x =
          baseX + math.sin(progress * math.pi * 2 * speed + seed * 10) * 12;
      final y = (baseY - progress * size.height * 0.08 * speed) % size.height;
      final adjustedY = y < 0 ? y + size.height : y;

      final opacity =
          (0.08 + seed * 0.12) *
          (0.5 + 0.5 * math.sin(progress * math.pi * 4 + seed * 6));

      paint.color = const Color(0xFFD4C5A9).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, adjustedY), 0.6 + seed * 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(_DustPainter old) => old.progress != progress;
}
