import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/diary_entry.dart';

/// History view for "My Pages" diary entries — shows entries chronologically
/// on the physical parchment, feeling like leafing through old pages.
class JourneyHistory extends StatelessWidget {
  const JourneyHistory({
    super.key,
    required this.entries,
    required this.onSelectEntry,
    required this.onClose,
    this.onDeleteEntry,
  });

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onSelectEntry;
  final VoidCallback onClose;
  final ValueChanged<DiaryEntry>? onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dim background.
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.85)),
        ),

        // Content.
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title.
                Text(
                  'JOURNEY',
                  style: GoogleFonts.caveat(
                    fontSize: 36,
                    color: const Color(0xFFD4C5A9),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your private pages',
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    color: const Color(0xFFD4C5A9).withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),

                // Entry list.
                if (entries.isEmpty)
                  Text(
                    'No entries yet...',
                    style: GoogleFonts.caveat(
                      fontSize: 20,
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.4),
                    ),
                  )
                else
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _buildEntryTile(context, entry);
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Close.
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0E06).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFD4C5A9).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'Back to desk',
                      style: GoogleFonts.caveat(
                        fontSize: 18,
                        color: const Color(0xFFD4C5A9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryTile(BuildContext context, DiaryEntry entry) {
    final dateStr = DateFormat('dd MMMM yyyy').format(entry.createdAt);
    final preview = entry.content.isEmpty
        ? 'Empty page'
        : (entry.content.length > 80
              ? '${entry.content.substring(0, 80)}...'
              : entry.content);

    return GestureDetector(
      onTap: () => onSelectEntry(entry),
      onLongPress: onDeleteEntry != null
          ? () => _confirmDelete(context, entry)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0E06).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      color: const Color(0xFFD4C5A9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDeleteEntry != null)
                  GestureDetector(
                    onTap: () => _confirmDelete(context, entry),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              preview,
              style: GoogleFonts.caveat(
                fontSize: 15,
                color: const Color(0xFFD4C5A9).withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0E06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.25),
          ),
        ),
        title: Text(
          'Remove page?',
          style: GoogleFonts.caveat(
            fontSize: 22,
            color: const Color(0xFFD4C5A9),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This page will be removed from your journey.',
          style: GoogleFonts.caveat(
            fontSize: 16,
            color: const Color(0xFFD4C5A9).withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.caveat(
                fontSize: 16,
                color: const Color(0xFFD4C5A9).withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDeleteEntry?.call(entry);
            },
            child: Text(
              'Remove',
              style: GoogleFonts.caveat(
                fontSize: 16,
                color: const Color(0xFFD4C5A9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
