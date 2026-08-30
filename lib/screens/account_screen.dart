import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/session_service.dart';

/// Account page — shows the currently authenticated user's information
/// with an editable profile picture.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isUploading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  void _loadAvatarUrl() {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _avatarUrl =
          user?.userMetadata?['avatar_url'] as String? ??
          user?.userMetadata?['picture'] as String?;
    });
  }

  // ── Avatar upload ──────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploading) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        throw ImageTooLargeException();
      }

      final ext = pickedFile.path.split('.').last.toLowerCase();

      final url = await SessionService.instance.uploadAvatar(
        bytes: bytes,
        fileExtension: ext,
      );

      if (!mounted) return;
      setState(() => _avatarUrl = url);
    } on ImageTooLargeException {
      if (!mounted) return;
      _showSnackBar('The image is too large. Please choose one under 5 MB.');
    } catch (e) {
      debugPrint('[Sacheta Account] Avatar upload error: $e');
      if (!mounted) return;
      _showSnackBar('The portrait could not be updated. Please try again.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 14,
            color: const Color(0xFFD4C5A9),
          ),
        ),
        backgroundColor: const Color(0xFF1A120A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: const Color(0xFFB8943E).withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = _extractFullName(user);
    final email = user?.email ?? 'Not available';
    final provider = _extractProvider(user);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0B08),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────
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

              // ── Body ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Editable avatar ──────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: SizedBox(
                            width: 84,
                            height: 84,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Avatar circle
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(
                                          0xFFB8943E,
                                        ).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _isUploading
                                          ? _buildLoadingAvatar()
                                          : (_avatarUrl != null &&
                                                  _avatarUrl!.isNotEmpty)
                                              ? Image.network(
                                                  _avatarUrl!,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (_, child, progress) {
                                                    if (progress == null) {
                                                      return child;
                                                    }
                                                    return _buildLoadingAvatar();
                                                  },
                                                  errorBuilder:
                                                      (_, _, _) =>
                                                          _buildDefaultAvatar(),
                                                )
                                              : _buildDefaultAvatar(),
                                    ),
                                  ),
                                ),

                                // Edit / camera badge
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0E0B08),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFB8943E,
                                        ).withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: _isUploading
                                        ? const Padding(
                                            padding: EdgeInsets.all(5),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.2,
                                              color: Color(0xFFB8943E),
                                            ),
                                          )
                                        : Icon(
                                            Icons.camera_alt_outlined,
                                            size: 13,
                                            color: const Color(
                                              0xFFB8943E,
                                            ).withValues(alpha: 0.7),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tap hint
                      Center(
                        child: Text(
                          _isUploading ? 'Updating…' : 'Tap to change',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 12,
                            color: const Color(
                              0xFFD4C5A9,
                            ).withValues(alpha: 0.3),
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Fields ───────────────────────────────
                      _AccountField(label: 'NAME', value: fullName),
                      const SizedBox(height: 28),
                      _AccountField(label: 'EMAIL', value: email),
                      const SizedBox(height: 28),
                      _AccountField(label: 'SIGN-IN METHOD', value: provider),
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

  // ── Avatar helpers ──────────────────────────────────────────────

  static Widget _buildLoadingAvatar() {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFF1A120A).withValues(alpha: 0.5),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFFB8943E),
          ),
        ),
      ),
    );
  }

  static Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A120A).withValues(alpha: 0.5),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 32,
          color: const Color(0xFFB8943E).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // ── User info helpers ───────────────────────────────────────────

  static String _extractFullName(User? user) {
    if (user == null) return 'Unknown';

    final metadata = user.userMetadata;
    if (metadata != null) {
      final fullName =
          metadata['full_name'] as String? ?? metadata['name'] as String?;
      if (fullName != null && fullName.isNotEmpty) return fullName;

      final firstName = metadata['first_name'] as String? ?? '';
      final lastName = metadata['last_name'] as String? ?? '';
      final combined = '$firstName $lastName'.trim();
      if (combined.isNotEmpty) return combined;
    }

    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Unknown';
  }

  static String _extractProvider(User? user) {
    if (user == null) return 'Not connected';

    final providers = user.appMetadata['providers'] as List<dynamic>?;
    if (providers != null && providers.isNotEmpty) {
      final provider = providers.first.toString();
      if (provider == 'google') return 'Google';
      if (provider == 'email') return 'Email';
      return provider[0].toString().toUpperCase() + provider.substring(1);
    }

    return 'Email';
  }
}

// ── Internal exception ──────────────────────────────────────────

class ImageTooLargeException implements Exception {
  @override
  String toString() => 'Image exceeds 5 MB limit.';
}

// ── Account field widget ────────────────────────────────────────

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
