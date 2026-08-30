import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Privacy Policy page — reflects the current state of Sacheta.
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
                            'private, reflective writing. This policy explains how '
                            'your information is handled when you use Sacheta.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'ACCOUNT & AUTHENTICATION',
                        body:
                            'Sacheta uses Google Sign-In to authenticate your '
                            'account. When you sign in with Google, Sacheta '
                            'receives your name, email address, and profile '
                            'picture from your Google account. This information '
                            'is used solely to identify your account and '
                            'personalize your experience within the app.\n\n'
                            'You may also create an account using an email '
                            'address and password. In this case, only your '
                            'email address is stored.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'YOUR DIARY ENTRIES',
                        body:
                            'Your diary entries are personal writing stored '
                            'securely in your account. Only you can access '
                            'your own entries. Sacheta does not read, analyze, '
                            'or share your private diary content with any '
                            'third party.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'SACHETA CONVERSATIONS',
                        body:
                            'When you speak with Sacheta, your messages are '
                            'processed to generate responses. These '
                            'conversations are stored in your account and are '
                            'used to provide the AI companion experience.\n\n'
                            'Conversation content may be processed by AI '
                            'services to generate replies. This processing '
                            'happens in real time and is used exclusively to '
                            'power your Sacheta experience.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'MEMORIES & CONTEXT',
                        body:
                            'Sacheta may retain memories and contextual '
                            'information from your interactions to provide a '
                            'more personalized and coherent experience over '
                            'time. This information is tied to your account '
                            'and is not shared with other users.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'AI PROCESSING',
                        body:
                            'Sacheta uses artificial intelligence to power '
                            'conversations and provide its companion features. '
                            'Your input is sent to AI services for processing '
                            'in order to generate responses. This processing '
                            'is conducted solely to provide the app\'s features '
                            'to you.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'DATA STORAGE & SECURITY',
                        body:
                            'Your account data, diary entries, and '
                            'conversations are stored on secure cloud servers. '
                            'Access to your data is protected by authentication '
                            '— only you, signed into your own account, can '
                            'access your information.\n\n'
                            'We take reasonable measures to protect your data, '
                            'but no method of storage or transmission is '
                            'completely secure.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'YOUR CONTROL',
                        body:
                            'You are in control of your data. You can:\n\n'
                            '• Access your account information at any time '
                            'from the Account section.\n'
                            '• Delete your diary entries and conversations '
                            'within the app.\n'
                            '• Log out of your account at any time.\n'
                            '• Request deletion of your account and all '
                            'associated data.',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'CHANGES TO THIS POLICY',
                        body:
                            'As Sacheta evolves, this privacy policy may be '
                            'updated to reflect new features or changes in '
                            'how your data is handled. Significant changes '
                            'will be communicated within the app.',
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
