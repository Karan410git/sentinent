import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'diary_entry.dart';

/// Simple local persistence for diary entries using a single JSON file.
/// No backend, no accounts — just local-first storage.
class DiaryRepository {
  DiaryRepository._();

  static final DiaryRepository instance = DiaryRepository._();

  static const _fileName = 'sacheta_entries.json';
  static const _uuid = Uuid();

  List<DiaryEntry>? _cache;

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Load all entries from disk (cached after first read).
  Future<List<DiaryEntry>> loadEntries() async {
    if (_cache != null) return _cache!;

    final f = await _file;
    if (!await f.exists()) {
      _cache = [];
      return _cache!;
    }

    final raw = await f.readAsString();
    final list = (json.decode(raw) as List<dynamic>)
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    // Most recent first.
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _cache = list;
    return _cache!;
  }

  /// Create a new blank entry and return it.
  Future<DiaryEntry> createEntry({String content = ''}) async {
    final entry = DiaryEntry(id: _uuid.v4(), content: content);

    final entries = await loadEntries();
    entries.insert(0, entry);
    await _persist(entries);

    return entry;
  }

  /// Update an existing entry's content.
  Future<DiaryEntry> updateEntry(String id, {required String content}) async {
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.id == id);

    if (index == -1) {
      throw StateError('Entry $id not found');
    }

    final updated = entries[index].copyWith(content: content);
    entries[index] = updated;
    await _persist(entries);

    return updated;
  }

  /// Delete an entry by id.
  Future<void> deleteEntry(String id) async {
    final entries = await loadEntries();
    entries.removeWhere((e) => e.id == id);
    await _persist(entries);
  }

  /// Get the most recent entry, or null if none exist.
  Future<DiaryEntry?> getLatestEntry() async {
    final entries = await loadEntries();
    return entries.isEmpty ? null : entries.first;
  }

  /// Get entry by id.
  Future<DiaryEntry?> getEntry(String id) async {
    final entries = await loadEntries();
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(List<DiaryEntry> entries) async {
    _cache = entries;
    final f = await _file;
    final json = entries.map((e) => e.toJson()).toList();
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }
}
