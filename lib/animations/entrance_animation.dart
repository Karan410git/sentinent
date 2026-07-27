import 'package:flutter/animation.dart';

class EntranceAnimation {
  final AnimationController controller;

  late final Animation<double> ember;
  late final Animation<double> reveal;
  late final Animation<double> warmth;
  late final Animation<double> settle;
  late final Animation<double> flicker;

  EntranceAnimation(this.controller) {
    ember = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.00, 0.12, curve: Curves.easeOut),
    );

    reveal = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.08, 0.78, curve: Curves.easeInOutCubic),
    );

    warmth = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.25, 0.90, curve: Curves.easeOut),
    );

    settle = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.70, 1.00, curve: Curves.easeOut),
    );

    flicker = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.90, 1.00, curve: Curves.easeInOut),
    );
  }
}
