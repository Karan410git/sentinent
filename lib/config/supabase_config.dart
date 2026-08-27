/// Supabase configuration — credentials for the Sacheta project.
///
/// The project URL is public and safe to include here.
/// The anon key is injected at build time via --dart-define.
///
/// Usage:
///   flutter run \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
class SupabaseConfig {
  const SupabaseConfig._();

  /// Supabase project URL (public, not a secret).
  static const String url = 'https://txeiddmtcaxwcdasjvrg.supabase.co';

  /// Supabase anonymous (public) key — injected at build time.
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether the anon key has been provided.
  static bool get isConfigured => anonKey.isNotEmpty;

  /// OAuth redirect URL for Supabase mobile auth (Google, etc.).
  /// Must match the redirect URL configured in Supabase Dashboard →
  /// Authentication → URL Configuration → Redirect URLs.
  static const String redirectTo = 'io.supabase.sentinent://login-callback/';
}
