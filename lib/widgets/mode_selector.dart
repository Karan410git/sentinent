import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The mode selector that appears after the camera push animation.
/// Two handwritten choices on a dark overlay — feels like part of the
/// physical diary experience, not a modern app menu.
class ModeSelector extends StatefulWidget {
  const ModeSelector({
    super.key,
    required this.onSelectMyPages,
    required this.onSelectSacheta,
    required this.onBack,
  });

  final VoidCallback onSelectMyPages;
  final VoidCallback onSelectSacheta;
  final VoidCallback onBack;

  @override
  State<ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<ModeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "My Pages" choice
              GestureDetector(
                onTap: widget.onSelectMyPages,
                child: _buildChoice(
                  label: 'My Pages',
                  subtitle: 'Your private journal',
                ),
              ),

              const SizedBox(height: 28),

              // "Sacheta" choice
              GestureDetector(
                onTap: widget.onSelectSacheta,
                child: _buildChoice(
                  label: 'Sacheta',
                  subtitle: 'Your ancient companion',
                ),
              ),

              const SizedBox(height: 36),

              // Back to desk.
              GestureDetector(
                onTap: widget.onBack,
                child: Text(
                  '← back to desk',
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    color: const Color(0xFFD4C5A9).withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoice({required String label, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E06).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFD4C5A9).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.caveat(
              fontSize: 32,
              color: const Color(0xFFD4C5A9),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.caveat(
              fontSize: 16,
              color: const Color(0xFFD4C5A9).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
