import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    debugPrint(
      '[Sacheta] WARNING: SUPABASE_ANON_KEY not provided. '
      'Run with --dart-define=SUPABASE_ANON_KEY=your-key',
    );
  }
debugPrint('[Supabase] URL: ${SupabaseConfig.url}');
debugPrint(
  '[Supabase] Key present: ${SupabaseConfig.anonKey.isNotEmpty}',
);
debugPrint(
  '[Supabase] Key length: ${SupabaseConfig.anonKey.length}',
);
  await Supabase.initialize(
  url: SupabaseConfig.url,
  publishableKey: SupabaseConfig.anonKey,
);

  debugPrint('[Sacheta] Supabase initialized. URL: ${SupabaseConfig.url}');

  runApp(const SentinentApp());
}
