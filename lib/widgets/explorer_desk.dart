import 'package:flutter/material.dart';

class ExplorerDesk extends StatelessWidget {
  const ExplorerDesk({super.key});

  static const String _assetPath =
      'assets/master/desk_portrait_master_final.png';

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        _assetPath,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
