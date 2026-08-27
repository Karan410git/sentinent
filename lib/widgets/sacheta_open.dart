import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/diary_entry.dart';

/// A single page of paginated text.
class _TextPage {
  const _TextPage({
    required this.text,
    required this.startOffset,
    required this.endOffset,
    this.featherSplitOffset = 0,
  });

  final String text;
  final int startOffset;
  final int endOffset;

  /// Character offset within [text] where the narrow (feather-zone) section
  /// ends and the full-width section begins. 0 means all text is full-width.
  final int featherSplitOffset;
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

/// The open diary view — a parchment page with handwritten text.
///
/// Uses `sacheta_page_blank.png` (portrait). The date is rendered above
/// the feather decoration. The first few lines flow beside the feather at
/// a narrow width, then automatically expand to full parchment width below
/// the feather. Text continues onto the next page when the current page
/// is full. Swipe left/right to navigate between pages.
class SachetaOpen extends StatefulWidget {
  const SachetaOpen({
    super.key,
    required this.entry,
    required this.onClose,
    this.onSave,
    this.onPreviousEntry,
    this.onNextEntry,
    this.hasPrevious = false,
    this.hasNext = false,
    this.isOpen = false,
  });

  final DiaryEntry? entry;
  final VoidCallback onClose;
  final ValueChanged<String>? onSave;
  final VoidCallback? onPreviousEntry;
  final VoidCallback? onNextEntry;
  final bool hasPrevious;
  final bool hasNext;
  final bool isOpen;

  @override
  State<SachetaOpen> createState() => _SachetaOpenState();
}

class _SachetaOpenState extends State<SachetaOpen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;
  late AnimationController _controlsOpacityController;
  late Animation<double> _controlsOpacity;

  // ── Multi-page state ──────────────────────────────────────────
  String _fullText = '';
  int _currentPageIndex = 0;
  List<_TextPage> _pages = [];
  bool _isUpdatingController = false;
  _WritableArea? _lastWritableArea;
  bool _slideForward = true;

  // ── Layout constants ──────────────────────────────────────────
  // Asset: sacheta_page_blank.png (752×1039 portrait).
  // The decorative feather/quill sits in the upper-left.
  // Writing starts beside the feather and expands to full width below it.
  static const double _writableTopFraction = 0.14;
  static const double _writableLeftFraction = 0.10;
  static const double _writableRightFraction = 0.10;
  static const double _writableBottomFraction = 0.09;

  // Feather collision zone — the rectangular no-write region that
  // closely follows the actual feather footprint.
  // x: 0.10 (left margin) to 0.55 (feather body right edge)
  // y: 0.14 (writable top) to 0.23 (feather tip + stem bottom)
  static const double _featherCollisionLeftFraction = 0.10;
  static const double _featherCollisionRightFraction = 0.55;
  static const double _featherCollisionBottomFraction = 0.23;
  // Padding below the feather tip so text clears it completely.
  static const double _featherCollisionPadFraction = 0.01;

  static const double _fontSize = 22;
  static const double _lineHeightRatio = 1.65;
  // Extra pixels to leave free at the bottom of each page to prevent overflow.
  static const double _bottomBufferPx = 48.0;

  @override
  void initState() {
    super.initState();
    _fullText = widget.entry?.content ?? '';
    _controller = TextEditingController(text: _fullText);
    _controller.addListener(_onTextChanged);

    _controlsOpacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controlsOpacity = CurvedAnimation(
      parent: _controlsOpacityController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant SachetaOpen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry?.id != oldWidget.entry?.id) {
      if (_hasUnsavedChanges &&
          oldWidget.entry != null &&
          widget.onSave != null) {
        _syncFullText();
        widget.onSave!(_fullText);
      }
      _fullText = widget.entry?.content ?? '';
      _controller.text = _fullText;
      _hasUnsavedChanges = false;
      _isEditing = false;
      _currentPageIndex = 0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _controlsOpacityController.dispose();
    super.dispose();
  }

  // ─── Text handling ────────────────────────────────────────────

  void _onTextChanged() {
    if (_isUpdatingController) return;
    _hasUnsavedChanges = true;

    _syncFullText();
    final oldPageCount = _pages.length;
    _recomputePages();

    // New page(s) appeared → auto-advance to the last page.
    if (_pages.length > oldPageCount) {
      _currentPageIndex = _pages.length - 1;
      _showPageInController(_currentPageIndex);
    }

    // Safety: clamp index.
    if (_currentPageIndex >= _pages.length) {
      _currentPageIndex = math.max(0, _pages.length - 1);
      _showPageInController(_currentPageIndex);
    }

    setState(() {});
  }

  /// Write the controller text back into `_fullText` at the current page's
  /// offset range so the full entry stays in sync.
  void _syncFullText() {
    if (_isUpdatingController || _pages.isEmpty) return;
    if (_currentPageIndex < 0 || _currentPageIndex >= _pages.length) return;

    final currentPage = _pages[_currentPageIndex];
    final before = _fullText.substring(0, currentPage.startOffset);
    final after = _fullText.substring(currentPage.endOffset);
    _fullText = before + _controller.text + after;
  }

  /// Replace the controller text with the given page's content without
  /// triggering the change listener recursion.
  void _showPageInController(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;
    _isUpdatingController = true;
    _controller.text = _pages[pageIndex].text;
    _controller.selection = TextSelection.collapsed(
      offset: _pages[pageIndex].text.length,
    );
    _isUpdatingController = false;
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pages.length || index == _currentPageIndex) {
      return;
    }

    _slideForward = index > _currentPageIndex;
    _syncFullText();
    _currentPageIndex = index;

    if (_currentPageIndex >= _pages.length) {
      _currentPageIndex = _pages.length - 1;
    }

    _showPageInController(_currentPageIndex);
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

  void _startEditing() {
    setState(() => _isEditing = true);
    _controlsOpacityController.reverse();
  }

  void _stopEditing() {
    setState(() => _isEditing = false);
    _controlsOpacityController.forward();
  }

  void _handleClose() {
    _syncFullText();
    if (_hasUnsavedChanges && widget.entry != null && widget.onSave != null) {
      widget.onSave!(_fullText);
    }
    widget.onClose();
  }

  // ─── Layout helpers ───────────────────────────────────────────

  /// Dark brown ink — visible on parchment.
  TextStyle get _handwritingStyle => GoogleFonts.caveat(
    fontSize: _fontSize,
    color: const Color(0xFF1A0E06),
    height: _lineHeightRatio,
    fontWeight: FontWeight.bold,
  );

  /// Date text uses the same warm tone as the feather/moon decoration.
  TextStyle get _dateStyle =>
      GoogleFonts.caveat(fontSize: 20, color: const Color(0xFFD4C5A9));

  double get _lineHeight => _fontSize * _lineHeightRatio;

  String _formatDate(DateTime date) {
    return 'Date: ${DateFormat('dd/MM/yyyy').format(date)}';
  }

  /// Compute the writable area relative to the *rendered image* rect.
  /// Writing starts beside the feather (y=0.14) and extends to the bottom.
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

  /// Measure [text] at [width] and return the character offsets where each
  /// visual line starts. Used to find where the feather-zone narrow lines end.
  List<int> _measureLineOffsets(String text, double width) {
    if (text.isEmpty) return [0];
    final tp = TextPainter(
      text: TextSpan(text: text, style: _handwritingStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: width);

    final metrics = tp.computeLineMetrics();
    final offsets = <int>[];
    var y = 0.0;
    for (var i = 0; i < metrics.length; i++) {
      final pos = tp.getPositionForOffset(
        Offset(0, y + metrics[i].height * 0.5),
      );
      offsets.add(pos.offset);
      y += metrics[i].height;
    }
    tp.dispose();
    return offsets;
  }

  void _recomputePages() {
    final area = _lastWritableArea;
    if (area == null) return;

    final text = _fullText;
    if (text.isEmpty) {
      _pages = [const _TextPage(text: '', startOffset: 0, endOffset: 0)];
      return;
    }

    // ── Feather zone geometry ─────────────────────────────────
    final featherZoneWidth =
        area.width *
        (_featherCollisionRightFraction - _featherCollisionLeftFraction);

    // Height of the feather zone expressed as a fraction of the writable area.
    final featherFraction =
        (_featherCollisionBottomFraction +
            _featherCollisionPadFraction -
            _writableTopFraction) /
        (1.0 - _writableTopFraction - _writableBottomFraction);
    final featherZoneHeight = area.height * featherFraction;
    final featherMaxLines = (featherZoneHeight / _lineHeight).floor();

    if (featherMaxLines <= 0) {
      // Feather zone too small — paginate everything at full width.
      _pages = _paginateUniform(text, area.width, area.height);
      return;
    }

    // ── Step 1: find where feather-zone narrow lines end ──────
    final narrowOffsets = _measureLineOffsets(text, featherZoneWidth);
    final splitIdx = math.min(featherMaxLines, narrowOffsets.length);
    final splitOffset = splitIdx < narrowOffsets.length
        ? narrowOffsets[splitIdx]
        : text.length;

    // ── Step 2: measure remaining text at full width ──────────
    final wideText = text.substring(splitOffset);
    final wideOffsets = _measureLineOffsets(wideText, area.width);

    // ── Step 3: build pages ───────────────────────────────────
    //
    // Page 1 layout:
    //   [feather-zone narrow lines]  ← featherZoneHeight pixels
    //   [full-width lines that fit]  ← area.height − featherZoneHeight
    //
    // Pages 2+ layout:
    //   [full-width lines]  ← area.height
    final wideMaxLinesPage1 =
        ((area.height - featherZoneHeight - _bottomBufferPx) / _lineHeight)
            .floor();
    final wideMaxLinesPerPage = ((area.height - _bottomBufferPx) / _lineHeight)
        .floor();

    _pages = [];

    if (wideText.isEmpty || wideOffsets.isEmpty) {
      // All text fits in the feather zone.
      _pages.add(
        _TextPage(
          text: text,
          startOffset: 0,
          endOffset: text.length,
          featherSplitOffset: splitOffset,
        ),
      );
      return;
    }

    // ── Page 1: narrow section + first full-width lines ───────
    final page1WideEnd = math.min(wideMaxLinesPage1, wideOffsets.length);
    final page1WideEndChar = page1WideEnd < wideOffsets.length
        ? wideOffsets[page1WideEnd]
        : wideText.length;

    _pages.add(
      _TextPage(
        text: text.substring(0, splitOffset + page1WideEndChar),
        startOffset: 0,
        endOffset: splitOffset + page1WideEndChar,
        featherSplitOffset: splitOffset,
      ),
    );

    // ── Pages 2+: full-width lines only ───────────────────────
    var wideLineIdx = page1WideEnd;
    while (wideLineIdx < wideOffsets.length) {
      final pageEndLine = math.min(
        wideLineIdx + wideMaxLinesPerPage,
        wideOffsets.length,
      );
      final startChar = wideOffsets[wideLineIdx];
      final endChar = pageEndLine < wideOffsets.length
          ? wideOffsets[pageEndLine]
          : wideText.length;

      _pages.add(
        _TextPage(
          text: text.substring(splitOffset + startChar, splitOffset + endChar),
          startOffset: splitOffset + startChar,
          endOffset: splitOffset + endChar,
        ),
      );

      wideLineIdx = pageEndLine;
    }

    if (_pages.isEmpty) {
      _pages = [const _TextPage(text: '', startOffset: 0, endOffset: 0)];
    }
  }

  /// Paginate text at a uniform width (no feather-zone split).
  List<_TextPage> _paginateUniform(
    String text,
    double width,
    double maxHeight,
  ) {
    if (text.isEmpty) {
      return [const _TextPage(text: '', startOffset: 0, endOffset: 0)];
    }

    final maxLines = ((maxHeight - _bottomBufferPx) / _lineHeight).floor();
    if (maxLines <= 0) {
      return [_TextPage(text: text, startOffset: 0, endOffset: text.length)];
    }

    final offsets = _measureLineOffsets(text, width);
    final totalLines = offsets.length;

    if (totalLines <= maxLines) {
      return [_TextPage(text: text, startOffset: 0, endOffset: text.length)];
    }

    final pages = <_TextPage>[];
    var lineIdx = 0;
    while (lineIdx < totalLines) {
      final pageEndLine = math.min(lineIdx + maxLines, totalLines);
      final startOffset = offsets[lineIdx];
      final endOffset = pageEndLine < totalLines
          ? offsets[pageEndLine]
          : text.length;
      pages.add(
        _TextPage(
          text: text.substring(startOffset, endOffset),
          startOffset: startOffset,
          endOffset: endOffset,
        ),
      );
      lineIdx = pageEndLine;
    }
    return pages.isEmpty
        ? [_TextPage(text: text, startOffset: 0, endOffset: text.length)]
        : pages;
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    if (_currentPageIndex >= _pages.length) {
      _currentPageIndex = math.max(0, _pages.length - 1);
    }

    final entryDate = widget.entry?.createdAt;
    final showDate = entryDate != null;

    return Stack(
      children: [
        // Dim background.
        GestureDetector(
          onTap: _isEditing ? null : _handleClose,
          child: Container(color: Colors.black.withValues(alpha: 0.85)),
        ),

        // Parchment page — LayoutBuilder measures the actual
        // rendered image so the writable area lines up with the
        // feather regardless of screen size.
        // Shift up when keyboard is visible so typed text stays on screen.
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Compute the rect the image occupies (BoxFit.contain).
                // Asset: sacheta_page_blank.png (752×1039 portrait).
                const assetAspect = 752.0 / 1039.0; // w / h
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

                // Date positioned in the dark area above the feather.
                final dateTop = imageTop - 40;

                return Stack(
                  children: [
                    // Date above the feather — same color as the feather/moon.
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
                      child: GestureDetector(
                        onTap: _isEditing ? null : _startEditing,
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
                              // Parchment texture with feather/quill —
                              // shown in full (contain) so the entire page
                              // is visible without cropping.
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

                              // Dark overlay for depth.
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

                              // Text content with swipe navigation —
                              // positioned within the writable area
                              // (beside the feather, then full width below).
                              Positioned(
                                left: writable.left - imageLeft,
                                top: writable.top - imageTop,
                                width: writable.width,
                                height: writable.height,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onHorizontalDragEnd: (details) {
                                    if (_isEditing) return;
                                    final velocity =
                                        details.primaryVelocity ?? 0;
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
                                    transitionBuilder:
                                        (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
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
                                      child: _isEditing
                                          ? _buildEditablePage()
                                          : _buildReadablePage(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ), // Padding
        ),

        // Page navigation arrows (left/right, flanking parchment).
        if (_pages.length > 1 && !_isEditing) ...[
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

        if (_pages.length > 1 && !_isEditing)
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: _buildPageIndicator(),
          ),

        // Exit button (top-left) — returns to the desk environment.
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

        // Save indicator.
        if (_hasUnsavedChanges && !_isEditing && widget.onSave != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 20,
            child: FadeTransition(
              opacity: _controlsOpacity,
              child: GestureDetector(
                onTap: () {
                  _syncFullText();
                  widget.onSave!(_fullText);
                  setState(() => _hasUnsavedChanges = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFFD4C5A9),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

        // Entry navigation arrows (between different diary entries).
        if (!_isEditing) ...[
          if (widget.hasPrevious)
            Positioned(
              left: 12,
              top: MediaQuery.sizeOf(context).height * 0.45,
              child: FadeTransition(
                opacity: _controlsOpacity,
                child: GestureDetector(
                  onTap: widget.onPreviousEntry,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
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
          if (widget.hasNext)
            Positioned(
              right: 12,
              top: MediaQuery.sizeOf(context).height * 0.45,
              child: FadeTransition(
                opacity: _controlsOpacity,
                child: GestureDetector(
                  onTap: widget.onNextEntry,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
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
      ],
    );
  }

  // ─── Sub-build methods ────────────────────────────────────────

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

  Widget _buildEditablePage() {
    return TextField(
      controller: _controller,
      autofocus: true,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: _handwritingStyle,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'Write your thoughts...',
        hintStyle: GoogleFonts.caveat(
          fontSize: 22,
          color: const Color(0xFF1A0E06).withValues(alpha: 0.4),
        ),
      ),
      onTapOutside: (_) => _stopEditing(),
    );
  }

  Widget _buildReadablePage() {
    final currentPage = _pages[_currentPageIndex];
    final text = currentPage.text;
    final isEmpty = text.trim().isEmpty;

    if (isEmpty && _currentPageIndex == 0) {
      return Center(
        child: Text(
          'Tap to write...',
          style: GoogleFonts.caveat(
            fontSize: 22,
            color: const Color(0xFF1A0E06).withValues(alpha: 0.35),
          ),
        ),
      );
    }

    final splitOffset = currentPage.featherSplitOffset;

    // No feather-zone section on this page — render at full width.
    if (splitOffset == 0) {
      return Text(text, style: _handwritingStyle);
    }

    final narrowText = text.substring(0, splitOffset);
    final wideText = text.substring(splitOffset);

    if (wideText.isEmpty) {
      // All text is in the narrow section (feather zone).
      return Text(narrowText, style: _handwritingStyle);
    }

    // Split display: narrow section on top (beside feather),
    // full-width below the feather.
    final area = _lastWritableArea;
    final featherZoneWidth = area != null
        ? area.width *
              (_featherCollisionRightFraction - _featherCollisionLeftFraction)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featherZoneWidth != null)
          SizedBox(
            width: featherZoneWidth,
            child: Text(narrowText, style: _handwritingStyle),
          )
        else
          Text(narrowText, style: _handwritingStyle),
        Text(wideText, style: _handwritingStyle),
      ],
    );
  }
}
