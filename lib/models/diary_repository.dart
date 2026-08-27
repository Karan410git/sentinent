import 'package:supabase_flutter/supabase_flutter.dart';

import 'diary_entry.dart';

/// Persistence for diary entries using Supabase.
/// Supabase is the single source of truth. RLS enforces per-user isolation.
class DiaryRepository {
  DiaryRepository._();

  static final DiaryRepository instance = DiaryRepository._();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ── Read ─────────────────────────────────────────────────────

  /// Load all diary entries for the current user, most recent first.
  Future<List<DiaryEntry>> loadEntries() async {
    final userId = _userId;
    if (userId == null) return [];

    final data = await _client
        .from('diary_pages')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => DiaryEntry.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  /// Get entry by id.
  Future<DiaryEntry?> getEntry(String id) async {
    final data = await _client
        .from('diary_pages')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return DiaryEntry.fromSupabase(data);
  }

  /// Get the most recent entry, or null.
  Future<DiaryEntry?> getLatestEntry() async {
    final entries = await loadEntries();
    return entries.isEmpty ? null : entries.first;
  }

  // ── Write ────────────────────────────────────────────────────

  /// Create a new blank diary page and return it.
  Future<DiaryEntry> createEntry({String content = ''}) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('No authenticated user');
    }

    final data = await _client
        .from('diary_pages')
        .insert({
          'user_id': userId,
          'content': content,
          'mode': 'my_pages',
          'page_date': DateTime.now().toIso8601String().substring(0, 10),
        })
        .select()
        .single();

    return DiaryEntry.fromSupabase(data);
  }

  /// Update an existing entry's content.
  Future<DiaryEntry> updateEntry(String id, {required String content}) async {
    final data = await _client
        .from('diary_pages')
        .update({'content': content})
        .eq('id', id)
        .select()
        .single();

    return DiaryEntry.fromSupabase(data);
  }

  /// Delete an entry by id.
  Future<void> deleteEntry(String id) async {
    await _client.from('diary_pages').delete().eq('id', id);
  }
}
