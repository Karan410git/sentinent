import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/initiation_screen.dart';
import '../services/session_service.dart';
import 'account_screen.dart';
import 'about_screen.dart';
import 'entrance_screen.dart';
import 'preferences_screen.dart';
import 'privacy_screen.dart';

/// "The Key" — Settings screen.
/// Uses the Sacheta visual language: dark sepia, parchment, muted gold.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onLogout,
    this.onHistory,
    this.onJourney,
  });

  final VoidCallback onLogout;
  final VoidCallback? onHistory;
  final VoidCallback? onJourney;

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
                      'THE KEY',
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

              // Menu items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      label: 'Account',
                      onTap: () => _open(context, const AccountScreen()),
                    ),
                    _SettingsTile(
                      icon: Icons.shield_outlined,
                      label: 'Privacy',
                      onTap: () => _open(context, const PrivacyScreen()),
                    ),
                    _SettingsTile(
                      icon: Icons.tune_outlined,
                      label: 'Preferences',
                      onTap: () => _open(context, const PreferencesScreen()),
                    ),
                    _SettingsTile(
                      icon: Icons.history,
                      label: 'History',
                      onTap: () {
                        Navigator.of(context).pop();
                        onHistory?.call();
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.route,
                      label: 'Journey',
                      onTap: () {
                        Navigator.of(context).pop();
                        onJourney?.call();
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      label: 'About Sacheta',
                      onTap: () => _open(context, const AboutScreen()),
                    ),
                    _SettingsTile(
                      icon: Icons.replay_outlined,
                      label: 'Revisit Introduction',
                      onTap: () async {
                        await SessionService.instance.resetIntroduction();
                        if (context.mounted) {
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.push(
                            MaterialPageRoute(
                              builder: (_) => InitiationScreen(
                                onComplete: () {
                                  nav.pop();
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    Divider(
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.06),
                      height: 1,
                    ),
                    const SizedBox(height: 8),

                    _SettingsTile(
                      icon: Icons.logout,
                      label: 'Leave / Log Out',
                      isDestructive: true,
                      onTap: () => _confirmLogout(context),
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A120A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
        title: Text(
          'Leave the pages?',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            color: const Color(0xFFD4C5A9),
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Text(
          'Your pages will remain safely stored.\nYou can return anytime.',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 15,
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.6),
            fontWeight: FontWeight.w300,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: const Color(0xFFD4C5A9).withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await SessionService.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => EntranceScreen(onNext: () {}),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: const Color(0xFF8B3A3A),
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _SettingsTile extends StatefulWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? const Color(0xFF8B3A3A)
        : const Color(0xFFD4C5A9).withValues(alpha: 0.6);
    final bgColor = _pressed
        ? const Color(0xFF1A120A).withValues(alpha: 0.4)
        : Colors.transparent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: bgColor,
        child: Row(
          children: [
            Icon(widget.icon, size: 20, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.label,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 17,
                  color: color,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: const Color(0xFFD4C5A9).withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
