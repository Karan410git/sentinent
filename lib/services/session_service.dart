import 'package:shared_preferences/shared_preferences.dart';

/// Manages temporary local sessions without real authentication.
///
/// Architecture is designed so that future real auth (Firebase, OAuth, etc.)
/// can replace this service without redesigning the UI layer.
class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _keyInSession = 'sacheta_in_session';
  static const _keyFirstLaunch = 'sacheta_first_launch';
  static const _keyOnboardingComplete = 'sacheta_onboarding_complete';
  static const _keyLanguageStyle = 'sacheta_language_style';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Whether the user currently has an active (temporary) session.
  Future<bool> get isInSession async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyInSession) ?? false;
  }

  /// Whether this is the very first time the app has been launched.
  Future<bool> get isFirstLaunch async {
    final prefs = await _getPrefs();
    // If the key has never been set, this is the first launch.
    return !prefs.containsKey(_keyFirstLaunch);
  }

  /// Whether the user has completed the initiation/onboarding flow.
  Future<bool> get hasCompletedIntroduction async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  /// Enter a temporary session (replaces real sign-in/sign-up for now).
  Future<void> enterTemporarySession() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyInSession, true);
    await prefs.setBool(_keyFirstLaunch, false);
  }

  /// Mark the onboarding/introduction as completed.
  Future<void> completeIntroduction() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  /// Reset introduction so the user can revisit it.
  Future<void> resetIntroduction() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyOnboardingComplete, false);
  }

  /// The user's preferred language style for Sacheta responses.
  /// Returns 'balanced' if not yet set.
  Future<String> get languageStyle async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyLanguageStyle) ?? 'balanced';
  }

  /// Persist the user's language style choice.
  Future<void> setLanguageStyle(String style) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyLanguageStyle, style);
  }

  /// Log out — clears session but NOT diary/conversation data.
  Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyInSession, false);
  }

  /// Full reset — for development / "Leave" scenarios.
  /// Clears session and onboarding state. Does NOT touch diary data.
  Future<void> fullReset() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyInSession);
    await prefs.remove(_keyOnboardingComplete);
  }
}
