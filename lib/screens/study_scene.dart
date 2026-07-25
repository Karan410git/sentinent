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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final EntranceAnimation _entrance;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _entrance = EntranceAnimation(_controller);

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const ExplorerDesk(),
              const SachetaClosed(),

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