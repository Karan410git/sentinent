import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Privacy Policy page — honest about current local-only state.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                      'PRIVACY',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section(
                        title: 'PRIVACY POLICY',
                        body:
                            'Sacheta is a personal diary application designed for '
                            'private, reflective writing.\n\n'
                            'This is a development version. Real account authentication '
                            'and cloud synchronization are not yet implemented.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'LOCAL STORAGE',
                        body:
                            'All diary entries and conversations are stored '
                            'locally on your device. No data is transmitted to '
                            'external servers during normal use.\n\n'
                            'The AI companion (Sacheta) sends conversation messages '
                            'to a local backend server for processing. This backend '
                            'runs on your device and does not transmit data externally.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'DATA OWNERSHIP',
                        body:
                            'Your diary entries and conversations belong to you. '
                            'They remain on your device until you choose to delete them.\n\n'
                            'Logging out does not delete your data. Your entries '
                            'and conversation history are preserved.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'ACCOUNTS',
                        body:
                            'In this version, no real accounts exist. You are '
                            'using a temporary local session. No personal information '
                            'is collected, stored, or transmitted.\n\n'
                            'When real authentication is implemented, this policy '
                            'will be updated to reflect actual data practices.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'FUTURE CHANGES',
                        body:
                            'As Sacheta evolves, cloud synchronization and '
                            'optional account features may be added. This privacy '
                            'policy will be updated to reflect any changes to '
                            'data handling practices.',
                      ),
                      const SizedBox(height: 40),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 12,
            color: const Color(0xFFB8943E).withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 15,
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.6),
            fontWeight: FontWeight.w300,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}
