import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ai_config.dart';

/// Preferences screen — Sacheta-styled settings for app behavior.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _autoSave = true;
  bool _ambientDust = true;
  bool _candleFlicker = true;
  String _languageStyle = 'balanced';

  @override
  void initState() {
    super.initState();
    _languageStyle = AIConfig.instance.languageStyle;
  }

  Future<void> _setLanguageStyle(String style) async {
    setState(() => _languageStyle = style);
    await AIConfig.instance.updateLanguageStyle(style);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B08),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 18,
                        color: const Color(0xFFD4C5A9).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PREFERENCES',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        color: const Color(0xFFD4C5A9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                color: const Color(0xFFD4C5A9).withValues(alpha: 0.08),
                height: 1,
              ),

              // Preferences list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    // ── Language Style section ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        'LANGUAGE STYLE',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 11,
                          color: const Color(0xFFB8943E).withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    _LanguageStyleOption(
                      label: 'Poetic',
                      subtitle: 'Ancient, philosophical, and metaphorical.',
                      selected: _languageStyle == 'poetic',
                      onTap: () => _setLanguageStyle('poetic'),
                    ),
                    _LanguageStyleOption(
                      label: 'Balanced',
                      subtitle: 'Poetic wisdom with clear, modern language.',
                      selected: _languageStyle == 'balanced',
                      onTap: () => _setLanguageStyle('balanced'),
                    ),
                    _LanguageStyleOption(
                      label: 'Simple',
                      subtitle: 'Clear, direct, and easy to understand.',
                      selected: _languageStyle == 'simple',
                      onTap: () => _setLanguageStyle('simple'),
                    ),

                    const SizedBox(height: 16),
                    Divider(
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.06),
                      height: 1,
                    ),
                    const SizedBox(height: 8),

                    // ── Other preferences ──
                    _PreferenceSwitch(
                      icon: Icons.save_outlined,
                      label: 'Auto Save',
                      subtitle: 'Save entries as you write',
                      value: _autoSave,
                      onChanged: (v) => setState(() => _autoSave = v),
                    ),
                    _PreferenceSwitch(
                      icon: Icons.grain,
                      label: 'Ambient Dust',
                      subtitle: 'Floating particles in the desk scene',
                      value: _ambientDust,
                      onChanged: (v) => setState(() => _ambientDust = v),
                    ),
                    _PreferenceSwitch(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Candle Flicker',
                      subtitle: 'Animated candlelight on the desk',
                      value: _candleFlicker,
                      onChanged: (v) => setState(() => _candleFlicker = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageStyleOption extends StatelessWidget {
  const _LanguageStyleOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? const Color(0xFFD4C5A9)
        : const Color(0xFFD4C5A9).withValues(alpha: 0.5);
    final bgColor = selected
        ? const Color(0xFF1A120A).withValues(alpha: 0.4)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        color: bgColor,
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected
                  ? const Color(0xFFB8943E)
                  : const Color(0xFFD4C5A9).withValues(alpha: 0.3),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 17,
                      color: textColor,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 13,
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.35),
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
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

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    color: const Color(0xFFD4C5A9).withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    color: const Color(0xFFD4C5A9).withValues(alpha: 0.35),
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFB8943E),
            inactiveThumbColor: const Color(0xFF5A4A30),
            inactiveTrackColor: const Color(0xFF2A1F14),
          ),
        ],
      ),
    );
  }
}
