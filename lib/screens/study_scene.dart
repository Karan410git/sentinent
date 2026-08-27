import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animations/entrance_animation.dart';
import '../models/conversation_repository.dart';
import '../models/diary_entry.dart';
import '../models/diary_repository.dart';
import '../models/sacheta_conversation.dart';
import '../widgets/ambient_dust_painter.dart';
import '../widgets/candle_glow.dart';
import '../widgets/conversation_history.dart';
import '../widgets/explorer_desk.dart';
import '../widgets/journey_history.dart';
import '../widgets/mode_selector.dart';
import '../widgets/sacheta_closed.dart';
import '../widgets/sacheta_conversation_view.dart';
import '../widgets/sacheta_open.dart';

import '../services/sacheta_mind.dart';
import '../services/ai_provider.dart';
import '../services/ai_config.dart';

/// Top-level state for the diary interaction.
enum _DiaryState {
  closed, // Diary sitting on desk.
  opening, // Opening animation in progress.
  modeSelect, // Camera pushed, showing My Pages / Sacheta choice.
  myPages, // Writing in My Pages.
  sacheta, // Sacheta conversation mode.
  journey, // Browsing My Pages history.
  history, // Browsing Sacheta conversation history.
}

class StudyScene extends StatefulWidget {
  const StudyScene({super.key});

  @override
  State<StudyScene> createState() => _StudySceneState();
}

class _StudySceneState extends State<StudyScene> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final EntranceAnimation _entrance;

  late final AnimationController _floatingController;
  late final AnimationController _ambientController;
  late final AnimationController _goldDustController;
  late final AnimationController _openSequenceController;
  late final AnimationController _sealWakeController;
  late final AnimationController _sealDustController;
  late final AnimationController _cameraController;
  late final AnimationController _diaryOpenController;
  late final AnimationController _modeSelectController;

  Timer? _goldDustTimer;

  final math.Random _random = math.Random();

  // Remember which section brought us here.
  _DiaryState? _lastTopLevelSection;

  _DiaryState _diaryState = _DiaryState.closed;

  // My Pages state.
  List<DiaryEntry> _entries = [];
  int _currentEntryIndex = 0;

  // Sacheta conversation state.
  List<SachetaConversation> _conversations = [];
  SachetaConversation? _activeConversation;
  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    _entrance = EntranceAnimation(_entranceController);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _goldDustController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _openSequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _sealWakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sealDustController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _diaryOpenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _modeSelectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startScene();
    AIConfig.instance.load();
  }

  Future<void> _startScene() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    await _entranceController.forward();
    if (!mounted) return;

    _floatingController.repeat(reverse: true);
    _scheduleNextGoldDust();
  }

  void _scheduleNextGoldDust() {
    _goldDustTimer?.cancel();
    final delaySeconds = 18 + _random.nextInt(13);

    _goldDustTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (!mounted || _diaryState != _DiaryState.closed) return;

      await _goldDustController.forward(from: 0);
      if (!mounted || _diaryState != _DiaryState.closed) return;

      _goldDustController.reset();
      _scheduleNextGoldDust();
    });
  }

  // ── Diary tap → opening sequence → mode selector ──────────────

  Future<void> _handleDiaryTap() async {
    if (_diaryState != _DiaryState.closed) return;

    setState(() {
      _diaryState = _DiaryState.opening;
    });

    _goldDustTimer?.cancel();

    await _floatingController.animateTo(
      0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    await _openSequenceController.forward(from: 0);
    if (!mounted) return;

    await _sealWakeController.forward(from: 0);
    if (!mounted) return;

    await _sealDustController.forward(from: 0);
    if (!mounted) return;

    await _cameraController.forward(from: 0);
    if (!mounted) return;

    // Show mode selector.
    await _modeSelectController.forward(from: 0);
    if (!mounted) return;

    setState(() {
      _diaryState = _DiaryState.modeSelect;
    });
  }

  // ── Mode selection ────────────────────────────────────────────

  Future<void> _handleSelectMyPages() async {
    if (_diaryState != _DiaryState.modeSelect) return;

    // Fade out mode selector.
    await _modeSelectController.reverse(from: 1);
    if (!mounted) return;

    // Always start a fresh blank diary page.
    final newEntry = await DiaryRepository.instance.createEntry();
    _entries = [newEntry];
    _currentEntryIndex = 0;

    // Open the diary.
    await _diaryOpenController.forward(from: 0);
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    setState(() {
      _diaryState = _DiaryState.myPages;
    });
  }

  Future<void> _handleSelectSacheta() async {
    if (_diaryState != _DiaryState.modeSelect) return;

    // Fade out mode selector.
    await _modeSelectController.reverse(from: 1);
    if (!mounted) return;

    // Load conversations.
    final conversations = await ConversationRepository.instance
        .loadConversations();
    if (!mounted) return;

    // Always start a new conversation — user can access
    // old ones from the history tab.
    final conv = await ConversationRepository.instance.createConversation();
    _conversations = [conv, ...conversations];
    _activeConversation = conv;

    // Open the diary.
    await _diaryOpenController.forward(from: 0);
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    setState(() {
      _diaryState = _DiaryState.sacheta;
    });
  }

  // ── Back to desk from mode selector ──────────────────────────

  Future<void> _backToDesk() async {
    if (_diaryState != _DiaryState.modeSelect) return;

    await _modeSelectController.reverse(from: 1);
    if (!mounted) return;

    await _cameraController.reverse(from: 1);
    if (!mounted) return;

    await _openSequenceController.reverse(from: 1);
    if (!mounted) return;

    _floatingController.repeat(reverse: true);
    _scheduleNextGoldDust();

    setState(() {
      _diaryState = _DiaryState.closed;
    });
  }

  // ── Back to mode select ───────────────────────────────────────

  Future<void> _backToModeSelect() async {
    if (_diaryState != _DiaryState.myPages &&
        _diaryState != _DiaryState.sacheta) {
      return;
    }

    setState(() {
      _diaryState = _DiaryState.opening;
    });

    await _diaryOpenController.reverse(from: 1);
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    await _cameraController.reverse(from: 1);
    if (!mounted) return;

    // Show mode selector again.
    await _modeSelectController.forward(from: 0);
    if (!mounted) return;

    setState(() {
      _diaryState = _DiaryState.modeSelect;
    });
  }

  // ── JOURNEY / HISTORY navigation ──────────────────────────────

  Future<void> _openJourney() async {
    if (_diaryState != _DiaryState.closed) return;

    _goldDustTimer?.cancel();

    // Quick camera push without full opening sequence.
    setState(() {
      _diaryState = _DiaryState.opening;
    });
    await _floatingController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    await _cameraController.forward(from: 0);
    if (!mounted) return;

    final entries = await DiaryRepository.instance.loadEntries();
    if (!mounted) return;

    // Fresh new Journey page on every entry from main selection.
    final newEntry = await DiaryRepository.instance.createEntry();
    _entries = [newEntry, ...entries];
    _currentEntryIndex = 0;

    await _diaryOpenController.forward(from: 0);
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    setState(() {
      _diaryState = _DiaryState.journey;
    });
  }

  Future<void> _openHistory() async {
    if (_diaryState != _DiaryState.closed) return;

    _goldDustTimer?.cancel();

    setState(() {
      _diaryState = _DiaryState.opening;
    });

    await _floatingController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    await _cameraController.forward(from: 0);
    if (!mounted) return;

    final conversations = await ConversationRepository.instance
        .loadConversations();
    if (!mounted) return;

    _conversations = conversations;

    await _diaryOpenController.forward(from: 0);
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    setState(() {
      _diaryState = _DiaryState.history;
    });
  }

  // ── Back from page/conversation to originating tab ───────────

  Future<void> _backToOriginatingSection() async {
    final origin = _lastTopLevelSection;
    if (origin == _DiaryState.journey) {
      final entries = await DiaryRepository.instance.loadEntries();
      _entries = entries;
      _lastTopLevelSection = null;
      setState(() {
        _diaryState = _DiaryState.journey;
      });
      return;
    }
    if (origin == _DiaryState.history) {
      final conversations = await ConversationRepository.instance.loadConversations();
      _conversations = conversations;
      _lastTopLevelSection = null;
      setState(() {
        _diaryState = _DiaryState.history;
      });
      return;
    }
    await _backToModeSelect();
  }

  // ── Back handler that preserves History / Journey origin ─────

  void _handleBackFromOpen() {
    if (_lastTopLevelSection == _DiaryState.journey ||
        _lastTopLevelSection == _DiaryState.history) {
      _backToOriginatingSection();
    } else {
      _backToModeSelect();
    }
  }

  Future<void> _closeHistory() async {
    if (_diaryState != _DiaryState.journey &&
        _diaryState != _DiaryState.history) {
      return;
    }

    setState(() {
      _diaryState = _DiaryState.opening;
    });

    await _diaryOpenController.reverse(from: 1);
    if (!mounted) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    await _cameraController.reverse(from: 1);
    if (!mounted) return;

    _floatingController.repeat(reverse: true);
    _scheduleNextGoldDust();

    setState(() {
      _diaryState = _DiaryState.closed;
    });
  }

  // ── Entry selection from JOURNEY ──────────────────────────────

  void _selectEntryFromJourney(DiaryEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _currentEntryIndex = index;
    }
    setState(() {
      _lastTopLevelSection = _DiaryState.journey;
      _diaryState = _DiaryState.myPages;
    });
  }

  // ── Conversation selection from HISTORY ───────────────────────

  void _selectConversationFromHistory(SachetaConversation conv) {
    _activeConversation = conv;
    setState(() {
      _lastTopLevelSection = _DiaryState.history;
      _diaryState = _DiaryState.sacheta;
    });
  }

  // ── Delete entry from journey ──────────────────────────────────

  Future<void> _deleteEntryFromJourney(DiaryEntry entry) async {
    await DiaryRepository.instance.deleteEntry(entry.id);
    if (!mounted) return;

    // Reload and keep state consistent.
    final entries = await DiaryRepository.instance.loadEntries();
    if (!mounted) return;

    _entries = entries;
    if (_currentEntryIndex >= _entries.length) {
      _currentEntryIndex = _entries.isEmpty ? 0 : _entries.length - 1;
    }
    setState(() {});
  }

  // ── Delete conversation from history ───────────────────────────

  Future<void> _deleteConversationFromHistory(SachetaConversation conv) async {
    await ConversationRepository.instance.deleteConversation(conv.id);
    if (!mounted) return;

    // Reload.
    _conversations = await ConversationRepository.instance.loadConversations();

    // If the active conversation was deleted, switch or null it out.
    if (_activeConversation?.id == conv.id) {
      _activeConversation = _conversations.isNotEmpty
          ? _conversations.first
          : null;
    }
    setState(() {});
  }

  // ── Sacheta: send message ─────────────────────────────────────

  Future<void> _handleSendMessage(String content) async {
    if (_activeConversation == null) return;

    // Add user message.
    final updated = await ConversationRepository.instance.addMessage(
      _activeConversation!.id,
      role: 'user',
      content: content,
    );

    if (!mounted) return;

    // Reload conversations list.
    _conversations = await ConversationRepository.instance.loadConversations();

    setState(() {
      _activeConversation = updated;
    });

    // Generate Sacheta's response via the AI layer.
    try {
      final sResponse = await SachetaMind.respond(
        conversationId: _activeConversation!.id,
        messages: updated.messages,
      );

      if (!mounted) return;

      final responseUpdated = await ConversationRepository.instance.addMessage(
        _activeConversation!.id,
        role: 'sacheta',
        content: sResponse,
      );

      if (!mounted) return;

      _conversations = await ConversationRepository.instance
          .loadConversations();

      setState(() {
        _activeConversation = responseUpdated;
      });

      // Background: extract memories from this exchange.
      SachetaMind.extractMemory(
        conversationId: _activeConversation!.id,
        messages: responseUpdated.messages,
      );
    } on AIProviderException catch (e) {
      if (!mounted) return;

      // Show a brief error within the conversation.
      final errorUpdated = await ConversationRepository.instance.addMessage(
        _activeConversation!.id,
        role: 'sacheta',
        content:
            'The ink fades for a moment... I cannot reach the other side.\n(${e.message})',
      );

      if (!mounted) return;

      _conversations = await ConversationRepository.instance
          .loadConversations();

      setState(() {
        _activeConversation = errorUpdated;
      });
    } catch (e) {
      if (!mounted) return;

      final fallback = await ConversationRepository.instance.addMessage(
        _activeConversation!.id,
        role: 'sacheta',
        content:
            'The pages whisper but the words do not come. Something is wrong with the connection.',
      );

      if (!mounted) return;

      _conversations = await ConversationRepository.instance
          .loadConversations();

      setState(() {
        _activeConversation = fallback;
      });
    }
  }

  // ── My Pages: save entry ──────────────────────────────────────

  Future<void> _saveEntry(String content) async {
    if (_entries.isEmpty) return;

    final entry = _entries[_currentEntryIndex];
    final updated = await DiaryRepository.instance.updateEntry(
      entry.id,
      content: content,
    );

    if (!mounted) return;

    setState(() {
      _entries[_currentEntryIndex] = updated;
    });
  }

  // ── Dispose ───────────────────────────────────────────────────

  @override
  void dispose() {
    _goldDustTimer?.cancel();

    _entranceController.dispose();
    _floatingController.dispose();
    _ambientController.dispose();
    _goldDustController.dispose();
    _openSequenceController.dispose();
    _sealWakeController.dispose();
    _sealDustController.dispose();
    _cameraController.dispose();
    _diaryOpenController.dispose();
    _modeSelectController.dispose();

    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceController,
          _floatingController,
          _ambientController,
          _goldDustController,
          _openSequenceController,
          _sealWakeController,
          _sealDustController,
          _cameraController,
          _diaryOpenController,
          _modeSelectController,
        ]),
        builder: (context, child) {
          final ambientElapsed = _ambientController.value * 12;

          final floatingProgress = Curves.easeInOutSine.transform(
            _floatingController.value,
          );

          final openProgress = Curves.easeOutBack.transform(
            _openSequenceController.value,
          );
          final settledOpenProgress = openProgress.clamp(0.0, 1.08);
          final diaryScale = 1 + (settledOpenProgress * 0.08);
          final diaryYOffset = -settledOpenProgress * 38;

          final sealGlowProgress = Curves.easeInOut.transform(
            _sealWakeController.value,
          );

          final sealDustProgress = Curves.easeInOutCubic.transform(
            _sealDustController.value,
          );

          final cameraProgress = Curves.easeInOutCubic.transform(
            _cameraController.value,
          );
          final cameraScale = 1 + cameraProgress * 0.38;
          final cameraYOffset = cameraProgress * 18;

          final diaryOpenProgress = Curves.easeInOut.transform(
            _diaryOpenController.value,
          );
          final showOpenView = _diaryOpenController.value > 0.01;

          final modeSelectProgress = _modeSelectController.value;
          final showModeSelect = modeSelectProgress > 0.01;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Desk scene.
              Transform.translate(
                offset: Offset(0, cameraYOffset),
                child: Transform.scale(
                  scale: cameraScale,
                  alignment: const Alignment(-0.04, 0.28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ExplorerDesk(),

                      // Closed diary.
                      Transform.translate(
                        offset: Offset(0, diaryYOffset),
                        child: Transform.scale(
                          scale: diaryScale,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _handleDiaryTap,
                            child: Opacity(
                              opacity: 1.0 - diaryOpenProgress,
                              child: SachetaClosed(
                                floatingProgress: floatingProgress,
                                goldDustProgress: _goldDustController.value,
                                sealGlowProgress: sealGlowProgress,
                                sealDustProgress: sealDustProgress,
                              ),
                            ),
                          ),
                        ),
                      ),

                      AmbientDust(elapsed: ambientElapsed),

                      // Loose page labels (JOURNEY / HISTORY).
                      if (_diaryState == _DiaryState.closed)
                        _buildLoosePageLabels(),
                    ],
                  ),
                ),
              ),

              // Candle glow.
              CandleGlow(entrance: _entrance),

              // Mode selector overlay.
              if (showModeSelect)
                Opacity(
                  opacity: modeSelectProgress,
                  child: ModeSelector(
                    onSelectMyPages: _handleSelectMyPages,
                    onSelectSacheta: _handleSelectSacheta,
                    onBack: _backToDesk,
                  ),
                ),

              // My Pages view.
              if (showOpenView && _diaryState == _DiaryState.myPages)
                Opacity(
                  opacity: diaryOpenProgress,
                  child: SachetaOpen(
                    entry: _entries.isNotEmpty
                        ? _entries[_currentEntryIndex]
                        : null,
                    isOpen: showOpenView,
                    onClose: _handleBackFromOpen,
                    onSave: _saveEntry,
                    hasPrevious: _currentEntryIndex < _entries.length - 1,
                    hasNext: _currentEntryIndex > 0,
                    onPreviousEntry: () =>
                        _navigateToEntry(_currentEntryIndex + 1),
                    onNextEntry: () => _navigateToEntry(_currentEntryIndex - 1),
                  ),
                ),

              // Sacheta conversation view.
              if (showOpenView && _diaryState == _DiaryState.sacheta)
                Opacity(
                  opacity: diaryOpenProgress,
                  child: SachetaConversationView(
                    conversation: _activeConversation,
                    isOpen: showOpenView,
                    onClose: _handleBackFromOpen,
                    onSendMessage: _handleSendMessage,
                  ),
                ),

              // JOURNEY history overlay.
              if (showOpenView && _diaryState == _DiaryState.journey)
                Opacity(
                  opacity: diaryOpenProgress,
                  child: JourneyHistory(
                    entries: _entries,
                    onSelectEntry: _selectEntryFromJourney,
                    onDeleteEntry: _deleteEntryFromJourney,
                    onClose: _closeHistory,
                  ),
                ),

              // HISTORY conversation list overlay.
              if (showOpenView && _diaryState == _DiaryState.history)
                Opacity(
                  opacity: diaryOpenProgress,
                  child: ConversationHistory(
                    conversations: _conversations,
                    onSelectConversation: _selectConversationFromHistory,
                    onDeleteConversation: _deleteConversationFromHistory,
                    onClose: _closeHistory,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToEntry(int index) {
    if (index < 0 || index >= _entries.length) return;
    setState(() => _currentEntryIndex = index);
  }

  // ── Loose page labels ─────────────────────────────────────────

  Widget _buildLoosePageLabels() {
    // Positioned on the left side of the desk, over the loose note pages.
    return Stack(
      children: [
        // JOURNEY label — on the upper loose page (left side).
        Positioned(
          left: MediaQuery.sizeOf(context).width * 0.11,
          top: MediaQuery.sizeOf(context).height * 0.60,
          child: _LooseLabel(text: 'JOURNEY', onTap: _openJourney),
        ),

        // HISTORY label — on the lower loose page (left side).
        Positioned(
          left: MediaQuery.sizeOf(context).width * 0.17,
          top: MediaQuery.sizeOf(context).height * 0.70,
          child: _LooseLabel(text: 'HISTORY', onTap: _openHistory),
        ),
      ],
    );
  }
}

/// A styled loose label for the desk — feels like handwritten text on
/// a physical scrap of paper, with a subtle ink-stain background.
/// Includes a press-scale animation for tactile feedback.
class _LooseLabel extends StatefulWidget {
  const _LooseLabel({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<_LooseLabel> createState() => _LooseLabelState();
}

class _LooseLabelState extends State<_LooseLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _pressScale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A0A).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: const Color(0xFFD4C5A9).withValues(alpha: 0.12),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: GoogleFonts.caveat(
              fontSize: 15,
              color: const Color(0xFFD4C5A9).withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
