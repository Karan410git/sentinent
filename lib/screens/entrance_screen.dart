import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/session_service.dart';
import 'initiation_screen.dart';
import 'study_scene.dart';

class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key, this.onNext});

  final VoidCallback? onNext;

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _dustController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

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

    _emailController.dispose();
    _passwordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  // ============================================================
  // AUTH
  // ============================================================

  Future<void> _handleSignIn() async {
    debugPrint('[Sacheta Auth UI] SIGN IN BUTTON PRESSED');

    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    debugPrint('[Sacheta Auth UI] Email: $email');
    debugPrint('[Sacheta Auth UI] Password provided: ${password.isNotEmpty}');

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'The pages need both ink and passphrase.';
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('[Sacheta Auth UI] Calling SessionService.signIn');

    final error = await SessionService.instance.signIn(
      email: email,
      password: password,
    );

    debugPrint('[Sacheta Auth UI] signIn returned: $error');

    if (!mounted) {
      debugPrint('[Sacheta Auth UI] EntranceScreen disposed after signIn');
      return;
    }

    if (error == null) {
      debugPrint('[Sacheta Auth UI] Sign-in SUCCESS');

      final onboardingDone =
          await SessionService.instance.hasCompletedIntroduction;
      if (!mounted) return;

      if (onboardingDone) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StudyScene()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InitiationScreen()),
        );
      }

      return;
    }

    debugPrint('[Sacheta Auth UI] Sign-in ERROR -> $error');

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  Future<void> _handleCreateAccount() async {
    debugPrint('[Sacheta Auth UI] CREATE ACCOUNT PRESSED');

    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'The pages need both ink and passphrase.';
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('[Sacheta Auth UI] Calling SessionService.signUp');

    final error = await SessionService.instance.signUp(
      email: email,
      password: password,
    );

    debugPrint('[Sacheta Auth UI] signUp returned: $error');

    if (!mounted) {
      debugPrint('[Sacheta Auth UI] EntranceScreen disposed after signUp');
      return;
    }

    if (error == null) {
      debugPrint('[Sacheta Auth UI] Sign-up SUCCESS');

      final onboardingDone =
          await SessionService.instance.hasCompletedIntroduction;
      if (!mounted) return;

      if (onboardingDone) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StudyScene()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InitiationScreen()),
        );
      }

      return;
    }

    if (error == '__email_confirmation_required__') {
      debugPrint('[Sacheta Auth UI] Email confirmation required');

      setState(() {
        _isLoading = false;
        _errorMessage =
            'A confirmation has been sent to your address.\n'
            'Check your ink-stained inbox.';
      });

      return;
    }

    debugPrint('[Sacheta Auth UI] Sign-up ERROR -> $error');

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  Future<void> _handleGoogle() async {
    if (!mounted) return;

    setState(() {
      _errorMessage =
          'Google has not yet been invited to these pages.\n'
          'Please use email for now.';
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

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
              const _Vignette(),

              AnimatedBuilder(
                animation: _dustController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DustPainter(progress: _dustController.value),
                    size: Size.infinite,
                  );
                },
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const Spacer(flex: 3),

                              // =================================================
                              // INTRO TEXT
                              // =================================================
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

                              const Spacer(flex: 1),

                              // =================================================
                              // EMAIL
                              // =================================================
                              FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _fadeController,
                                  curve: const Interval(0.5, 1.0),
                                ),
                                child: _AuthField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  hint: 'your.ink@address',
                                  keyboardType: TextInputType.emailAddress,
                                  onSubmitted: (_) {
                                    _passwordFocus.requestFocus();
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              // =================================================
                              // PASSWORD
                              // =================================================
                              FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _fadeController,
                                  curve: const Interval(0.5, 1.0),
                                ),
                                child: _AuthField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  hint: 'passphrase',
                                  obscure: true,
                                  onSubmitted: (_) {
                                    _handleSignIn();
                                  },
                                ),
                              ),

                              // =================================================
                              // ERROR
                              // =================================================
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 14),

                                FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _fadeController,
                                    curve: const Interval(0.5, 1.0),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 13,
                                      color: const Color(0xFF8B5E3C),
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],

                              const Spacer(flex: 1),

                              // =================================================
                              // BUTTONS
                              // =================================================
                              FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _fadeController,
                                  curve: const Interval(0.5, 1.0),
                                ),
                                child: Column(
                                  children: [
                                    _EntranceButton(
                                      label: 'CONTINUE WITH GOOGLE',
                                      onTap: _handleGoogle,
                                      isPrimary: true,
                                    ),

                                    const SizedBox(height: 14),

                                    _EntranceButton(
                                      label: _isLoading
                                          ? 'OPENING...'
                                          : 'SIGN IN',
                                      onTap: _isLoading ? () {} : _handleSignIn,
                                    ),

                                    const SizedBox(height: 14),

                                    _EntranceButton(
                                      label: 'CREATE ACCOUNT',
                                      onTap: _isLoading
                                          ? () {}
                                          : _handleCreateAccount,
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(flex: 1),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// AUTH FIELD
// ================================================================

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 15,
        color: const Color(0xFFD4C5A9).withValues(alpha: 0.8),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      cursorColor: const Color(0xFFB8943E).withValues(alpha: 0.6),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cormorantGaramond(
          fontSize: 15,
          color: const Color(0xFFD4C5A9).withValues(alpha: 0.25),
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
        ),
        filled: true,
        fillColor: const Color(0xFF0F0B08).withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: const Color(0xFFB8943E).withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// VIGNETTE
// ================================================================

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

// ================================================================
// ENTRANCE BUTTON
// ================================================================

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
      onTapDown: (_) {
        _pressController.forward();
      },
      onTapUp: (_) {
        _pressController.reverse();
      },
      onTapCancel: () {
        _pressController.reverse();
      },
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

// ================================================================
// DUST
// ================================================================

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
  bool shouldRepaint(_DustPainter old) {
    return old.progress != progress;
  }
}
