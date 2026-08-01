import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animations/entrance_animation.dart';
import '../widgets/candle_glow.dart';
import '../widgets/explorer_desk.dart';
import '../widgets/sacheta_closed.dart';

class StudyScene extends StatefulWidget {
  const StudyScene({super.key});

  @override
  State<StudyScene> createState() => _StudySceneState();
}

class _StudySceneState extends State<StudyScene>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final EntranceAnimation _entrance;

  late final AnimationController _floatingController;
  late final AnimationController _goldDustController;
  late final AnimationController _openSequenceController;
  late final AnimationController _sealWakeController;

  Timer? _goldDustTimer;

  final math.Random _random = math.Random();

  bool _isOpening = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _entrance = EntranceAnimation(
      _entranceController,
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );

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
    

    _startScene();
  }

  Future<void> _startScene() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted) {
      return;
    }

    await _entranceController.forward();

    if (!mounted) {
      return;
    }

    _floatingController.repeat(
      reverse: true,
    );

    _scheduleNextGoldDust();
  }

  void _scheduleNextGoldDust() {
    _goldDustTimer?.cancel();

    final delaySeconds = 18 + _random.nextInt(13);

    _goldDustTimer = Timer(
      Duration(seconds: delaySeconds),
      () async {
        if (!mounted || _isOpening) {
          return;
        }

        await _goldDustController.forward(
          from: 0,
        );

        if (!mounted || _isOpening) {
          return;
        }

        _goldDustController.reset();
        _scheduleNextGoldDust();
      },
    );
  }

  Future<void> _handleDiaryTap() async {
    if (_isOpening) {
      return;
    }

    setState(() {
      _isOpening = true;
    });

    _goldDustTimer?.cancel();

    await _floatingController.animateTo(
      0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );

    if (!mounted) {
      return;
    }

    await _openSequenceController.forward(
  from: 0,
);

if (!mounted) {
  return;
}

await _sealWakeController.forward(
  from: 0,
);
  }

  @override
  void dispose() {
    _goldDustTimer?.cancel();

    _entranceController.dispose();
    _floatingController.dispose();
    _goldDustController.dispose();
    _openSequenceController.dispose();
    _sealWakeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceController,
          _floatingController,
          _goldDustController,
          _openSequenceController,
          _sealWakeController,
        ]),
        builder: (context, child) {
          final floatingProgress =
    Curves.easeInOutSine.transform(
  _floatingController.value,
);

final openProgress = Curves.easeOutBack.transform(
  _openSequenceController.value,
);

final settledOpenProgress =
    openProgress.clamp(0.0, 1.08);

final diaryScale =
    1 + (settledOpenProgress * 0.08);

final diaryYOffset =
    -settledOpenProgress * 38;

          final sealGlowProgress =
              Curves.easeInOut.transform(_sealWakeController.value);

          return Stack(
            fit: StackFit.expand,
            children: [
              const ExplorerDesk(),

              Transform.translate(
                offset: Offset(
                  0,
                  diaryYOffset,
                ),
                child: Transform.scale(
                  scale: diaryScale,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _handleDiaryTap,
                    child: SachetaClosed(
                      floatingProgress: floatingProgress,
                      goldDustProgress:
                          _goldDustController.value,
                      sealGlowProgress: sealGlowProgress,
                    ),
                  ),
                ),
              ),

              CandleGlow(
                entrance: _entrance,
              ),
            ],
          );
        },
      ),
    );
  }
}