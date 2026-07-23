import 'package:flutter/material.dart';
import '../features/study/presentation/study_scene.dart';

class SentinentApp extends StatelessWidget {
  const SentinentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const StudyScene(),
    );
  }
}