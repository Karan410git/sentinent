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

class _StudySceneState extends State<StudyScene> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final EntranceAnimation _entrance;

  late final AnimationController _floatingController;
  late final AnimationController _goldDustController;

  Timer? _goldDustTimer;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _entrance = EntranceAnimation(_entranceController);

    // A complete rise and return takes roughly 12 seconds
    // because repeat(reverse: true) plays both directions.
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );

    _goldDustController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _startScene();
  }

  Future<void> _startScene() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) {
      return;
    }

    await _entranceController.forward();

    if (!mounted) {
      return;
    }

    _floatingController.repeat(reverse: true);

    _scheduleNextGoldDust();
  }

  void _scheduleNextGoldDust() {
    _goldDustTimer?.cancel();

    // For testing, temporarily use:
    // final delaySeconds = 4 + _random.nextInt(3);

    final delaySeconds = 18 + _random.nextInt(13);

    _goldDustTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (!mounted) {
        return;
      }

      await _goldDustController.forward(from: 0);

      if (!mounted) {
        return;
      }

      _goldDustController.reset();
      _scheduleNextGoldDust();
    });
  }

  @override
  void dispose() {
    _goldDustTimer?.cancel();

    _entranceController.dispose();
    _floatingController.dispose();
    _goldDustController.dispose();

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
        ]),
        builder: (context, child) {
          final floatingProgress = Curves.easeInOutCubic.transform(
            _floatingController.value,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              const ExplorerDesk(),

              SachetaClosed(
                floatingProgress: floatingProgress,
                goldDustProgress: _goldDustController.value,
              ),

              CandleGlow(entrance: _entrance),
            ],
          );
        },
      ),
    );
  }
}
