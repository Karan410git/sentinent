/// Supabase configuration — reads credentials from build-time environment.
///
/// Usage (when Phase 2 activates this):
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// Or via a .env file loaded at build time.
///
/// This file is intentionally NOT imported anywhere yet.
/// It will be wired in during Phase 2 (Flutter ↔ Supabase connection).
class SupabaseConfig {
  const SupabaseConfig._();

  /// Your Supabase project URL, e.g. https://xyzcompany.supabase.co
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// Your Supabase anonymous (public) key — safe to ship in the client.
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether both values are present and non-empty.
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url != 'https://your-project-ref.supabase.co';
}
