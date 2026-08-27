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

/// Determines which screen to show based on session state.
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

  Future<void> _resolve() async {
    final inSession = await SessionService.instance.isInSession;
    if (!inSession) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final onboardingDone =
        await SessionService.instance.hasCompletedIntroduction;
    if (mounted) {
      setState(() {
        _loading = false;
        _inSession = inSession;
        _onboardingDone = onboardingDone;
      });
    }
  }

  bool _inSession = false;
  bool _onboardingDone = false;

  void _goToEntrance() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntranceScreen(onNext: _checkAfterEntrance),
      ),
    );
  }

  void _checkAfterEntrance() async {
    final onboardingDone =
        await SessionService.instance.hasCompletedIntroduction;
    if (!mounted) return;

    if (onboardingDone) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => StudyScene()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InitiationScreen(
            onComplete: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => StudyScene()),
                (route) => false,
              );
            },
          ),
        ),
      );
    }
  }

  void _goToDesk() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => StudyScene()));
  }

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

    if (_inSession && _onboardingDone) {
      // Returning user — go straight to desk.
      // Use addPostFrameCallback to avoid setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToDesk());
      return const Scaffold(backgroundColor: Color(0xFF0A0806));
    }

    // No session or first time — show entrance.
    // Use addPostFrameCallback to avoid setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToEntrance());
    return const Scaffold(backgroundColor: Color(0xFF0A0806));
  }
}
