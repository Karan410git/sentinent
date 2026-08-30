import 'session_service.dart';

/// Central configuration for the AI layer.
///
/// Stores the backend URL and language style preference.
/// API keys live exclusively on the server.
class AIConfig {
  AIConfig._();

  static final AIConfig instance = AIConfig._();

  String _backendUrl = 'https://sentinent-kohl.vercel.app';

  /// 'poetic', 'balanced', or 'simple'.
  String _languageStyle = 'balanced';

  bool _loaded = false;

  String get backendUrl => _backendUrl;

  /// Current language style for Sacheta responses.
  String get languageStyle => _languageStyle;

  /// Load config. Safe to call multiple times (cached).
  Future<void> load() async {
    if (_loaded) return;
    _languageStyle = await SessionService.instance.languageStyle;
    _loaded = true;
  }

  /// Update the backend URL.
  void updateBackendUrl(String url) {
    _backendUrl = url;
  }

  /// Update the language style and persist it.
  Future<void> updateLanguageStyle(String style) async {
    _languageStyle = style;
    await SessionService.instance.setLanguageStyle(style);
  }
}
