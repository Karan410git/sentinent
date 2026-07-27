import 'package:flutter/material.dart';

import 'sacheta_renderer.dart';

class SachetaClosed extends StatelessWidget {
  const SachetaClosed({
    super.key,
    this.widthFactor = 0.66,
    this.alignment = const Alignment(0, 0.18),
    this.floatingProgress = 0,
    this.goldDustProgress = 0,
  });

  final double widthFactor;
  final Alignment alignment;
  final double floatingProgress;
  final double goldDustProgress;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: screenWidth * widthFactor,
        child: SachetaRenderer(
          assetPath: 'assets/master/sacheta_closed_master_final.png',
          floatingProgress: floatingProgress,
          goldDustProgress: goldDustProgress,
        ),
      ),
    );
  }
}
