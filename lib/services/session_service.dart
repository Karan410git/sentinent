import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages authentication via Supabase and local preferences.
///
/// Introduction completion and language style are local-only
/// (SharedPreferences). Authentication is Supabase-backed.
class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _keyLanguageStyle = 'sacheta_language_style';

  SupabaseClient get _client => Supabase.instance.client;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Auth (Supabase) ───────────────────────────────────────────

  /// The currently authenticated Supabase user, or null.
  User? get currentUser => _client.auth.currentUser;

  /// Whether there is an authenticated user.
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes from Supabase.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email and password.
  ///
  /// Returns an error message string on failure, or null on success.
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return 'The pages could not accept this offering. Please try again.';
      }

      if (response.session == null) {
        return '__email_confirmation_required__';
      }

      return null;
    } on AuthException catch (e) {
      debugPrint('[Sacheta Auth] SignUp AuthException: ${e.message}');
      return _mapAuthError(e);
    } catch (e) {
      debugPrint(
        '[Sacheta Auth] SignUp unexpected error: ${e.runtimeType}: $e',
      );
      return 'The pages are quiet tonight. Something went wrong.';
    }
  }

  /// Sign in with email and password.
  ///
  /// Returns an error message string on failure, or null on success.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return 'The ink smudges... those credentials do not open these pages.';
      }

      return null;
    } on AuthException catch (e) {
      debugPrint('[Sacheta Auth] SignIn AuthException: ${e.message}');
      return _mapAuthError(e);
    } catch (e) {
      debugPrint(
        '[Sacheta Auth] SignIn unexpected error: ${e.runtimeType}: $e',
      );
      return 'The pages are quiet tonight. Something went wrong.';
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Introduction (local) ──────────────────────────────────────

  String _onboardingKeyForUser() {
    final user = currentUser;

    if (user == null) {
      return 'sacheta_onboarding_complete_no_user';
    }

    return 'sacheta_onboarding_complete_${user.id}';
  }

  /// Whether the current authenticated user has completed
  /// the initiation/onboarding flow.
  Future<bool> get hasCompletedIntroduction async {
    final prefs = await _getPrefs();
    final key = _onboardingKeyForUser();

    final completed = prefs.getBool(key) ?? false;

    debugPrint('[Sacheta Session] onboarding key: $key');
    debugPrint('[Sacheta Session] onboarding completed: $completed');

    return completed;
  }

  /// Mark onboarding as completed for the current user.
  Future<void> completeIntroduction() async {
    final prefs = await _getPrefs();
    final key = _onboardingKeyForUser();

    await prefs.setBool(key, true);

    debugPrint(
      '[Sacheta Session] onboarding completed for current user',
    );
  }

  /// Reset onboarding for the current user.
  Future<void> resetIntroduction() async {
    final prefs = await _getPrefs();
    final key = _onboardingKeyForUser();

    await prefs.setBool(key, false);

    debugPrint(
      '[Sacheta Session] onboarding reset for current user',
    );
  }

  // ── Language Style (local) ────────────────────────────────────

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

  // ── Legacy compatibility ─────────────────────────────────────

  /// Alias for signOut — used by existing SettingsScreen code.
  Future<void> logout() async => signOut();

  // ── Error mapping ─────────────────────────────────────────────

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        (msg.contains('invalid') && msg.contains('credentials'))) {
      return 'The ink smudges... those credentials do not open these pages.';
    }

    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user already exists')) {
      return 'The pages already know this name. Try signing in instead.';
    }

    if (msg.contains('password') &&
        (msg.contains('weak') || msg.contains('at least'))) {
      return 'The binding is too weak. Choose a stronger passphrase — at least 6 characters.';
    }

    if (msg.contains('valid email') || msg.contains('valid format')) {
      return 'That address does not look like ink on parchment. Please enter a valid email.';
    }

    if (msg.contains('email not confirmed') ||
        msg.contains('confirm your email')) {
      return 'A confirmation has been sent to your address. Check your ink-stained inbox.';
    }

    if (msg.contains('network') || msg.contains('timeout')) {
      return 'The pages are quiet tonight. The connection seems to have drifted.';
    }

    // Fallback — don't expose raw Supabase errors.
    return 'Something stirred in the pages, but they could not respond. Please try again.';
  }
}