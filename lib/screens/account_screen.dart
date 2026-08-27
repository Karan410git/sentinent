import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Account page — shows temporary visitor status.
/// Architecture prepared for future real auth fields.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

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
                      'ACCOUNT',
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

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visitor status
                      _AccountField(
                        label: 'STATUS',
                        value: 'Temporary Visitor',
                      ),
                      const SizedBox(height: 28),
                      _AccountField(label: 'SESSION', value: 'Local session'),
                      const SizedBox(height: 28),
                      _AccountField(
                        label: 'DISPLAY NAME',
                        value: 'Not yet set',
                      ),
                      const SizedBox(height: 28),
                      _AccountField(label: 'EMAIL', value: 'Not connected'),
                      const SizedBox(height: 28),
                      _AccountField(
                        label: 'AUTHENTICATION',
                        value: 'None — temporary local session',
                      ),

                      const Spacer(),

                      // Future note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A120A).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(
                              0xFFD4C5A9,
                            ).withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Real account features will be available in a future update. '
                          'Your diary data is stored locally on this device.',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 14,
                            color: const Color(
                              0xFFD4C5A9,
                            ).withValues(alpha: 0.4),
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

class _AccountField extends StatelessWidget {
  const _AccountField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 11,
            color: const Color(0xFFB8943E).withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 17,
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
