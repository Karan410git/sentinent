import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/entrance_screen.dart';
import '../screens/initiation_screen.dart';
import '../screens/study_scene.dart';
import '../services/session_service.dart';

class SentinentApp extends StatelessWidget {
  const SentinentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sacheta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const _EntryGate(),
    );
  }
}

class _EntryGate extends StatefulWidget {
  const _EntryGate();

  @override
  State<_EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<_EntryGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  // ─────────────────────────────────────────────────────────────
  // Startup resolution
  // ─────────────────────────────────────────────────────────────

  Future<void> _resolve() async {
    debugPrint('[Sacheta Navigation] EntryGate resolving...');

    // Wait a frame so Supabase can restore any persisted session.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final user = SessionService.instance.currentUser;

    debugPrint(
      '[Sacheta Navigation] Current user: '
      '${user?.email ?? 'NONE'}',
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (user == null) {
      debugPrint('[Sacheta Navigation] No authenticated user -> Entrance');
      _navigateToEntrance();
      return;
    }

    debugPrint(
      '[Sacheta Navigation] Authenticated user -> checking introduction',
    );

    final onboardingDone =
        await SessionService.instance.hasCompletedIntroduction;

    if (!mounted) return;

    debugPrint('[Sacheta Navigation] onboardingDone = $onboardingDone');

    if (onboardingDone) {
      debugPrint('[Sacheta Navigation] -> StudyScene');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudyScene()),
        (route) => false,
      );
    } else {
      debugPrint('[Sacheta Navigation] -> InitiationScreen');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const InitiationScreen()),
        (route) => false,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Navigate to entrance
  // ─────────────────────────────────────────────────────────────

  void _navigateToEntrance() {
    debugPrint('[Sacheta Navigation] -> EntranceScreen');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => EntranceScreen(onNext: () {})),
      (route) => false,
    );
  }

  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0806),
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              color: Color(0xFFB8943E),
            ),
          ),
        ),
      );
    }

    // Black scaffold shown briefly while navigation executes.
    return const Scaffold(backgroundColor: Color(0xFF0A0806));
  }
}
