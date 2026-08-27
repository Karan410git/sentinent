/// Central configuration for the AI layer.
///
/// Stores only the backend URL. API keys live exclusively on the
/// server — never in the Flutter application.
class AIConfig {
  AIConfig._();

  static final AIConfig instance = AIConfig._();

  String _backendUrl = 'http://192.168.0.106:3000';

  bool _loaded = false;

  String get backendUrl => _backendUrl;

  /// Load config. Safe to call multiple times (cached).
  Future<void> load() async {
    if (_loaded) return;
    // Backend URL is currently hardcoded.
    // Future: load from shared_preferences or environment.
    _loaded = true;
  }

  /// Update the backend URL.
  void updateBackendUrl(String url) {
    _backendUrl = url;
  }
}
