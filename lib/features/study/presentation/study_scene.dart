import 'package:flutter/material.dart';

class StudyScene extends StatelessWidget {
  const StudyScene({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(
        child: ColoredBox(
          color: Colors.black,
        ),
      ),
    );
  }
}