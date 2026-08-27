import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/sacheta_conversation.dart';

/// History view for Sacheta conversations — shows conversations chronologically.
class ConversationHistory extends StatelessWidget {
  const ConversationHistory({
    super.key,
    required this.conversations,
    required this.onSelectConversation,
    required this.onClose,
    this.onDeleteConversation,
  });

  final List<SachetaConversation> conversations;
  final ValueChanged<SachetaConversation> onSelectConversation;
  final VoidCallback onClose;
  final ValueChanged<SachetaConversation>? onDeleteConversation;

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
                  'HISTORY',
                  style: GoogleFonts.caveat(
                    fontSize: 36,
                    color: const Color(0xFFD4C5A9),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Conversations with Sacheta',
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    color: const Color(0xFFD4C5A9).withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),

                // Conversation list.
                if (conversations.isEmpty)
                  Text(
                    'No conversations yet...',
                    style: GoogleFonts.caveat(
                      fontSize: 20,
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.4),
                    ),
                  )
                else
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        return _buildConversationTile(context, conv);
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

  Widget _buildConversationTile(
    BuildContext context,
    SachetaConversation conv,
  ) {
    final dateStr = DateFormat('dd MMMM yyyy').format(conv.createdAt);
    final messageCount = conv.messages.length;
    final preview = conv.preview;

    return GestureDetector(
      onTap: () => onSelectConversation(conv),
      onLongPress: onDeleteConversation != null
          ? () => _confirmDelete(context, conv)
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
                Text(
                  dateStr,
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    color: const Color(0xFFD4C5A9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$messageCount messages',
                  style: GoogleFonts.caveat(
                    fontSize: 14,
                    color: const Color(0xFFD4C5A9).withValues(alpha: 0.4),
                  ),
                ),
                if (onDeleteConversation != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, conv),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.35),
                    ),
                  ),
                ],
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

  void _confirmDelete(BuildContext context, SachetaConversation conv) {
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
          'Remove conversation?',
          style: GoogleFonts.caveat(
            fontSize: 22,
            color: const Color(0xFFD4C5A9),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This conversation will be removed from history.',
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
              onDeleteConversation?.call(conv);
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
