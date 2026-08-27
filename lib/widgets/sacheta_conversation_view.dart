import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/sacheta_conversation.dart';

/// A single page of paginated conversation text.
class _ConversationPage {
  const _ConversationPage({
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });

  final String text;
  final int startOffset;
  final int endOffset;
}

/// Bounding box for the writable area (excludes margins).
class _WritableArea {
  const _WritableArea({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

/// The Sacheta conversation view — displays AI conversation on the
/// same physical parchment page. Uses uniform full-width layout
/// (no feather-zone split) for maximum writable space, starting
/// from the top of the page.
class SachetaConversationView extends StatefulWidget {
  const SachetaConversationView({
    super.key,
    required this.conversation,
    required this.isOpen,
    required this.onClose,
    required this.onSendMessage,
  });

  final SachetaConversation? conversation;
  final bool isOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onSendMessage;

  @override
  State<SachetaConversationView> createState() =>
      _SachetaConversationViewState();
}

class _SachetaConversationViewState extends State<SachetaConversationView>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;

  // ── Multi-page state ──────────────────────────────────────────
  String _fullText = '';
  int _currentPageIndex = 0;
  List<_ConversationPage> _pages = [];
  _WritableArea? _lastWritableArea;
  bool _slideForward = true;

  // ── Layout constants ──────────────────────────────────────────
  // Uniform full-width layout — writing starts from the top.
  static const double _writableTopFraction = 0.08;
  static const double _writableLeftFraction = 0.10;
  static const double _writableRightFraction = 0.10;
  static const double _writableBottomFraction = 0.09;

  static const double _userFontSize = 22;
  static const double _sachetaFontSize = 19;
  static const double _lineHeightRatio = 1.65;
  static const double _bottomBufferPx = 48.0;

  @override
  void initState() {
    super.initState();
    _fullText = _conversationToText(widget.conversation);
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SachetaConversationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldMsgCount = oldWidget.conversation?.messages.length ?? 0;
    final newMsgCount = widget.conversation?.messages.length ?? 0;
    final oldTextLen = _fullText.length;

    if (widget.conversation?.id != oldWidget.conversation?.id ||
        newMsgCount != oldMsgCount) {
      _fullText = _conversationToText(widget.conversation);

      // Auto-advance to last page when content grows (new message arrived).
      final contentGrew =
          _fullText.length > oldTextLen ||
          widget.conversation?.id != oldWidget.conversation?.id;

      _recomputePages();

      if (contentGrew && _pages.isNotEmpty) {
        _currentPageIndex = _pages.length - 1;
      } else if (_currentPageIndex >= _pages.length) {
        _currentPageIndex = math.max(0, _pages.length - 1);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Text handling ────────────────────────────────────────────

  String _conversationToText(SachetaConversation? conv) {
    if (conv == null || conv.messages.isEmpty) return '';

    final buf = StringBuffer();
    for (final msg in conv.messages) {
      final prefix = msg.role == 'user' ? 'You: ' : 'Sacheta: ';
      buf.writeln('$prefix${msg.content}');
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pages.length || index == _currentPageIndex) {
      return;
    }

    _slideForward = index > _currentPageIndex;
    _currentPageIndex = index;

    if (_currentPageIndex >= _pages.length) {
      _currentPageIndex = _pages.length - 1;
    }

    setState(() {});
  }

  void _swipeToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _goToPage(_currentPageIndex + 1);
    }
  }

  void _swipeToPreviousPage() {
    if (_currentPageIndex > 0) {
      _goToPage(_currentPageIndex - 1);
    }
  }

  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _controller.clear();
    // Text rebuild is handled by didUpdateWidget when parent setState fires.
  }

  void _handleClose() {
    widget.onClose();
  }

  // ─── Layout helpers ───────────────────────────────────────────

  TextStyle _handwritingStyleForRole(String role) => GoogleFonts.caveat(
    fontSize: role == 'sacheta' ? _sachetaFontSize : _userFontSize,
    color: const Color(0xFF1A0E06),
    height: _lineHeightRatio,
    fontWeight: FontWeight.bold,
  );

  TextStyle get _dateStyle =>
      GoogleFonts.caveat(fontSize: 20, color: const Color(0xFFD4C5A9));

  TextStyle get _userLabelStyle => GoogleFonts.caveat(
    fontSize: 18,
    color: const Color(0xFF8B6914),
    fontWeight: FontWeight.bold,
  );

  TextStyle get _sachetaLabelStyle => GoogleFonts.caveat(
    fontSize: 18,
    color: const Color(0xFF5B3A8C),
    fontWeight: FontWeight.bold,
  );

  String _formatDate(DateTime date) {
    return 'Date: ${DateFormat('dd/MM/yyyy').format(date)}';
  }

  _WritableArea _computeWritableAreaFromImage(
    double imageLeft,
    double imageTop,
    double imageWidth,
    double imageHeight,
  ) {
    return _WritableArea(
      left: imageLeft + imageWidth * _writableLeftFraction,
      top: imageTop + imageHeight * _writableTopFraction,
      width: imageWidth * (1 - _writableLeftFraction - _writableRightFraction),
      height:
          imageHeight * (1 - _writableTopFraction - _writableBottomFraction),
    );
  }

  /// Paginate the conversation text using uniform full-width layout.
  /// Each line is measured individually per-role to handle mixed font sizes.
  void _recomputePages() {
    final area = _lastWritableArea;
    if (area == null) return;

    final text = _fullText;
    if (text.isEmpty) {
      _pages = [
        const _ConversationPage(text: '', startOffset: 0, endOffset: 0),
      ];
      return;
    }

    // Compute effective line height using a mix of both sizes.
    // We use the user font as baseline since it's the larger one.
    final effectiveLineHeight = _userFontSize * _lineHeightRatio;
    final maxLines = ((area.height - _bottomBufferPx) / effectiveLineHeight)
        .floor();

    if (maxLines <= 0) {
      _pages = [
        _ConversationPage(text: text, startOffset: 0, endOffset: text.length),
      ];
      return;
    }

    // Split text into lines, measure each at full width with its own style,
    // and assign line offsets.
    final lines = text.split('\n');
    final lineOffsets = <int>[];
    var offset = 0;
    for (final line in lines) {
      lineOffsets.add(offset);
      // Newline character adds 1 to offset.
      offset += line.length + 1;
    }
    // Add the final offset (end of text).
    lineOffsets.add(text.length);

    _pages = [];
    var lineIdx = 0;
    while (lineIdx < lines.length) {
      final pageEndLine = math.min(lineIdx + maxLines, lines.length);
      final startOffset = lineOffsets[lineIdx];
      final endOffset = pageEndLine < lines.length
          ? lineOffsets[pageEndLine]
          : text.length;

      _pages.add(
        _ConversationPage(
          text: text.substring(startOffset, endOffset),
          startOffset: startOffset,
          endOffset: endOffset,
        ),
      );

      lineIdx = pageEndLine;
    }

    if (_pages.isEmpty) {
      _pages = [
        const _ConversationPage(text: '', startOffset: 0, endOffset: 0),
      ];
    }
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    if (_currentPageIndex >= _pages.length) {
      _currentPageIndex = math.max(0, _pages.length - 1);
    }

    final entryDate = widget.conversation?.createdAt;
    final showDate = entryDate != null;

    return Stack(
      children: [
        // Dim background.
        GestureDetector(
          onTap: _handleClose,
          child: Container(color: Colors.black.withValues(alpha: 0.85)),
        ),

        // Parchment page — shift up when keyboard is visible.
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const assetAspect = 752.0 / 1039.0;
                final containerAspect =
                    constraints.maxWidth / constraints.maxHeight;

                double imageW, imageH;
                if (assetAspect > containerAspect) {
                  imageW = constraints.maxWidth;
                  imageH = imageW / assetAspect;
                } else {
                  imageH = constraints.maxHeight;
                  imageW = imageH * assetAspect;
                }

                final imageLeft = (constraints.maxWidth - imageW) / 2;
                final imageTop = (constraints.maxHeight - imageH) / 2;

                final writable = _computeWritableAreaFromImage(
                  imageLeft,
                  imageTop,
                  imageW,
                  imageH,
                );
                _lastWritableArea = writable;
                _recomputePages();

                final dateTop = imageTop - 40;

                return Stack(
                  children: [
                    // Date.
                    if (showDate)
                      Positioned(
                        left: imageLeft,
                        top: dateTop,
                        width: imageW,
                        child: Center(
                          child: Text(
                            _formatDate(entryDate),
                            style: _dateStyle,
                          ),
                        ),
                      ),

                    // Parchment page.
                    Positioned(
                      left: imageLeft,
                      top: imageTop,
                      width: imageW,
                      height: imageH,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 40,
                              spreadRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Center(
                                child: Image.asset(
                                  'assets/master/sacheta_page_blank.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(0x08000000),
                                    const Color(0x15000000),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),

                            // Text content.
                            Positioned(
                              left: writable.left - imageLeft,
                              top: writable.top - imageTop,
                              width: writable.width,
                              height: writable.height,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragEnd: (details) {
                                  final velocity = details.primaryVelocity ?? 0;
                                  const threshold = 100.0;
                                  if (velocity < -threshold) {
                                    _swipeToNextPage();
                                  } else if (velocity > threshold) {
                                    _swipeToPreviousPage();
                                  }
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) {
                                    final isEntering =
                                        child.key ==
                                        ValueKey<int>(_currentPageIndex);
                                    final beginOffset = isEntering
                                        ? (_slideForward
                                              ? const Offset(0.25, 0.0)
                                              : const Offset(-0.25, 0.0))
                                        : (_slideForward
                                              ? const Offset(-0.25, 0.0)
                                              : const Offset(0.25, 0.0));
                                    return SlideTransition(
                                      position:
                                          Tween<Offset>(
                                            begin: beginOffset,
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            ),
                                          ),
                                      child: FadeTransition(
                                        opacity: CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeIn,
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey<int>(_currentPageIndex),
                                    child: _buildConversationPage(),
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
              },
            ),
          ),
        ),

        // Page navigation arrows.
        if (_pages.length > 1) ...[
          Positioned(
            left: 16,
            bottom: MediaQuery.sizeOf(context).height * 0.42,
            child: GestureDetector(
              onTap: _currentPageIndex > 0 ? _swipeToPreviousPage : null,
              child: AnimatedOpacity(
                opacity: _currentPageIndex > 0 ? 1.0 : 0.25,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0E06).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFFD4C5A9),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.sizeOf(context).height * 0.42,
            child: GestureDetector(
              onTap: _currentPageIndex < _pages.length - 1
                  ? _swipeToNextPage
                  : null,
              child: AnimatedOpacity(
                opacity: _currentPageIndex < _pages.length - 1 ? 1.0 : 0.25,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0E06).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD4C5A9).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFD4C5A9),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],

        if (_pages.length > 1)
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: _buildPageIndicator(),
          ),

        // Exit button.
        Positioned(
          top: MediaQuery.paddingOf(context).top + 16,
          left: 20,
          child: GestureDetector(
            onTap: _handleClose,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4C5A9).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFD4C5A9),
                size: 20,
              ),
            ),
          ),
        ),

        // Message input at bottom — shifts up with keyboard.
        Positioned(
          bottom:
              MediaQuery.paddingOf(context).bottom +
              MediaQuery.of(context).viewInsets.bottom +
              12,
          left: 20,
          right: 20,
          child: _buildMessageInput(),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pages.length, (i) {
        final isActive = i == _currentPageIndex;
        return GestureDetector(
          onTap: () => _goToPage(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 10 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: Color(isActive ? 0x80D4C5A9 : 0x40D4C5A9),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildConversationPage() {
    final currentPage = _pages[_currentPageIndex];
    final text = currentPage.text;
    final isEmpty = text.trim().isEmpty;

    if (isEmpty) {
      return Center(
        child: Text(
          'Start a conversation...',
          style: GoogleFonts.caveat(
            fontSize: 22,
            color: const Color(0xFF1A0E06).withValues(alpha: 0.35),
          ),
        ),
      );
    }

    // Render the conversation with role labels.
    final lines = text.split('\n');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          if (line.startsWith('You: ')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'You: ', style: _userLabelStyle),
                    TextSpan(
                      text: line.substring(5),
                      style: _handwritingStyleForRole('user'),
                    ),
                  ],
                ),
              ),
            );
          } else if (line.startsWith('Sacheta: ')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Sacheta: ', style: _sachetaLabelStyle),
                    TextSpan(
                      text: line.substring(9),
                      style: _handwritingStyleForRole('sacheta'),
                    ),
                  ],
                ),
              ),
            );
          } else if (line.isEmpty) {
            return const SizedBox(height: 8);
          } else {
            return Text(line, style: _handwritingStyleForRole('user'));
          }
        }).toList(),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E06).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4C5A9).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.caveat(
                fontSize: 18,
                color: const Color(0xFFD4C5A9),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Write to Sacheta...',
                hintStyle: GoogleFonts.caveat(
                  fontSize: 18,
                  color: const Color(0xFFD4C5A9).withValues(alpha: 0.4),
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSendMessage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4C5A9).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFFD4C5A9),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
