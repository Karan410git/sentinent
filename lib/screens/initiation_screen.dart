import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ai_config.dart';
import '../services/session_service.dart';
import 'study_scene.dart';

/// First-time initiation — Sacheta introduces itself and its world.
/// 5 steps: Sacheta, History, Journey, The Key, Language Style, then final.
class InitiationScreen extends StatefulWidget {
  const InitiationScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<InitiationScreen> createState() => _InitiationScreenState();
}

class _InitiationScreenState extends State<InitiationScreen>
    with TickerProviderStateMixin {
  int _step = 0; // 0..4 = intro steps, 5 = final transition
  late final AnimationController _transitionController;
  late final AnimationController _fadeController;

  /// Language style choice — defaults to 'balanced'.
  String _languageStyle = 'balanced';

  @override
  void initState() {
    super.initState();
    // Pre-load current preference so revisit shows the current choice.
    _languageStyle = AIConfig.instance.languageStyle;
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  static const _totalIntroSteps = 5; // 0..4

  Future<void> _advance() async {
    if (_step < _totalIntroSteps) {
      // Fade out current
      await _fadeController.reverse(from: 1.0);
      if (!mounted) return;

      setState(() => _step++);

      if (_step == _totalIntroSteps) {
        // Final transition — "The pages are yours now."
        _fadeController.duration = const Duration(milliseconds: 1200);
        _fadeController.forward();
        await Future<void>.delayed(const Duration(milliseconds: 2000));
        if (!mounted) return;

        // Persist the language style choice.
        await AIConfig.instance.updateLanguageStyle(_languageStyle);
        await SessionService.instance.completeIntroduction();

        // Navigate using our own context (the parent may be disposed).
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StudyScene()),
          (route) => false,
        );
      } else {
        _fadeController.duration = const Duration(milliseconds: 900);
        _fadeController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0806),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: FadeTransition(
          opacity: _fadeController,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: _buildStepContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_step == _totalIntroSteps) {
      return _buildFinalTransition();
    }

    // The Language Style step (step 4) has a custom UI.
    if (_step == 4) {
      return _buildLanguageStyleStep();
    }

    final steps = _InitiationStepData.steps;
    final data = steps[_step];

    return Column(
      children: [
        const Spacer(flex: 2),

        // Step indicator dots
        _buildStepDots(),

        const SizedBox(height: 48),

        // Highlight circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFB8943E).withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB8943E).withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              data.icon,
              size: 36,
              color: const Color(0xFFB8943E).withValues(alpha: 0.7),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Title
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30,
            color: const Color(0xFFD4C5A9),
            fontWeight: FontWeight.w400,
            letterSpacing: 1.0,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 20),

        // Subtitle
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 17,
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.55),
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            height: 1.6,
            letterSpacing: 0.3,
          ),
        ),

        const Spacer(flex: 3),

        // Continue button
        GestureDetector(
          onTap: _advance,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A120A).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFB8943E).withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              _step == _totalIntroSteps - 1 ? 'ENTER' : 'TAP TO CONTINUE',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13,
                color: const Color(0xFFD4C5A9).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                letterSpacing: 2.5,
              ),
            ),
          ),
        ),

        const Spacer(flex: 1),
      ],
    );
  }

  // ── Step indicator dots ────────────────────────────────────────

  Widget _buildStepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalIntroSteps, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: i == _step ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == _step
                ? const Color(0xFFB8943E).withValues(alpha: 0.8)
                : const Color(0xFFD4C5A9).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ── Language Style step ────────────────────────────────────────

  Widget _buildLanguageStyleStep() {
    return Column(
      children: [
        const Spacer(flex: 2),

        _buildStepDots(),

        const SizedBox(height: 48),

        // Title
        Text(
          'How would you like\nSacheta to speak?',
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            color: const Color(0xFFD4C5A9),
            fontWeight: FontWeight.w400,
            letterSpacing: 1.0,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'You can change this later from the Key.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 14,
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.4),
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 36),

        // Options
        _StyleChoice(
          label: 'Poetic',
          subtitle: 'Ancient, philosophical, and metaphorical.',
          selected: _languageStyle == 'poetic',
          onTap: () => setState(() => _languageStyle = 'poetic'),
        ),
        const SizedBox(height: 10),
        _StyleChoice(
          label: 'Balanced',
          subtitle: 'Poetic wisdom with clear, modern language.',
          recommended: true,
          selected: _languageStyle == 'balanced',
          onTap: () => setState(() => _languageStyle = 'balanced'),
        ),
        const SizedBox(height: 10),
        _StyleChoice(
          label: 'Simple',
          subtitle: 'Clear, direct, and easy to understand.',
          selected: _languageStyle == 'simple',
          onTap: () => setState(() => _languageStyle = 'simple'),
        ),

        const Spacer(flex: 3),

        // Continue button
        GestureDetector(
          onTap: _advance,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A120A).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFB8943E).withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              'ENTER',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13,
                color: const Color(0xFFD4C5A9).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                letterSpacing: 2.5,
              ),
            ),
          ),
        ),

        const Spacer(flex: 1),
      ],
    );
  }

  // ── Final transition ───────────────────────────────────────────

  Widget _buildFinalTransition() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '"The pages are yours now."',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              color: const Color(0xFFD4C5A9),
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Begin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              color: const Color(0xFFB8943E).withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Style choice tile ──────────────────────────────────────────────

class _StyleChoice extends StatelessWidget {
  const _StyleChoice({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.recommended = false,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFFB8943E).withValues(alpha: 0.5)
        : const Color(0xFFD4C5A9).withValues(alpha: 0.1);
    final bgColor = selected
        ? const Color(0xFF1A120A).withValues(alpha: 0.5)
        : const Color(0xFF0F0B08).withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected
                  ? const Color(0xFFB8943E)
                  : const Color(0xFFD4C5A9).withValues(alpha: 0.3),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 16,
                          color: selected
                              ? const Color(0xFFD4C5A9)
                              : const Color(0xFFD4C5A9).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFB8943E,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 9,
                              color: const Color(
                                0xFFB8943E,
                              ).withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14,
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.4),
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step data ─────────────────────────────────────────────────────

class _InitiationStepData {
  const _InitiationStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Steps 0–3. Step 4 (Language Style) is built separately.
  static const steps = [
    _InitiationStepData(
      title: 'Sacheta',
      subtitle:
          'Your companion within these pages.\nSpeak with it, question it, or simply listen.',
      icon: Icons.auto_stories,
    ),
    _InitiationStepData(
      title: 'History',
      subtitle:
          'Your record of moments shared with Sacheta —\nyour pages and conversations, preserved through time.\n\nYou can revisit History anytime from the Key.',
      icon: Icons.history,
    ),
    _InitiationStepData(
      title: 'Journey',
      subtitle:
          'A reflection of how your relationship\nwith Sacheta unfolds over time.\n\nYou can revisit Journey anytime from the Key.',
      icon: Icons.route,
    ),
    _InitiationStepData(
      title: 'The Key',
      subtitle:
          'Your account, privacy, preferences,\nHistory, Journey, and the secrets of this place.',
      icon: Icons.vpn_key,
    ),
  ];
}
