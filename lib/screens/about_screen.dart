import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// About Sacheta — atmospheric, like a page from the world.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                      'ABOUT',
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
                    horizontal: 36,
                    vertical: 40,
                  ),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        'SACHETA',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 28,
                          color: const Color(0xFFD4C5A9),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tagline
                      Text(
                        '"A place for thoughts that deserve to remain."',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 17,
                          color: const Color(0xFFD4C5A9).withValues(alpha: 0.5),
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Sections
                      _AboutSection(
                        title: 'MY PAGES',
                        body:
                            'A private writing space. Write freely — '
                            'your thoughts remain yours, stored only on '
                            'this device.',
                      ),
                      const SizedBox(height: 28),
                      _AboutSection(
                        title: 'SACHETA',
                        body:
                            'An AI companion that lives within these pages. '
                            'Speak with it, question it, or simply listen. '
                            'It remembers what you share.',
                      ),
                      const SizedBox(height: 28),
                      _AboutSection(
                        title: 'YOUR JOURNEY',
                        body:
                            'What you have written does not disappear. '
                            'Return to moments you\'ve left behind — diary '
                            'entries and conversations, preserved.',
                      ),
                      const SizedBox(height: 28),
                      _AboutSection(
                        title: 'DESIGN',
                        body:
                            'Sacheta is designed as an immersive digital diary. '
                            'Not a productivity app. Not a note-taking tool. '
                            'A world for your thoughts.',
                      ),

                      const SizedBox(height: 48),
                      Text(
                        'v1.0.0',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 13,
                          color: const Color(
                            0xFFD4C5A9,
                          ).withValues(alpha: 0.25),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
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

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.body});

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
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.55),
            fontWeight: FontWeight.w300,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}
