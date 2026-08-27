import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'sacheta_conversation.dart';
import 'sacheta_message.dart';

/// Local persistence for Sacheta conversations using a single JSON file.
/// Separate from DiaryRepository — conversations and My Pages are isolated.
class ConversationRepository {
  ConversationRepository._();

  static final ConversationRepository instance = ConversationRepository._();

  static const _fileName = 'sacheta_conversations.json';
  static const _memoryFileName = 'sacheta_memory.json';
  static const _uuid = Uuid();

  List<SachetaConversation>? _cache;
  Map<String, dynamic>? _memoryCache;

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<File> get _memoryFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_memoryFileName');
  }

  // ── Conversations ──────────────────────────────────────────────

  /// Load all conversations from disk (cached after first read).
  Future<List<SachetaConversation>> loadConversations() async {
    if (_cache != null) return _cache!;

    final f = await _file;
    if (!await f.exists()) {
      _cache = [];
      return _cache!;
    }

    final raw = await f.readAsString();
    final list = (json.decode(raw) as List<dynamic>)
        .map((e) => SachetaConversation.fromJson(e as Map<String, dynamic>))
        .toList();

    // Most recent first.
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    _cache = list;
    return _cache!;
  }

  /// Create a new conversation and return it.
  Future<SachetaConversation> createConversation() async {
    final conversation = SachetaConversation(id: _uuid.v4(), messages: []);

    final conversations = await loadConversations();
    conversations.insert(0, conversation);
    await _persistConversations(conversations);

    return conversation;
  }

  /// Add a message to a conversation and persist.
  Future<SachetaConversation> addMessage(
    String conversationId, {
    required String role,
    required String content,
  }) async {
    final conversations = await loadConversations();
    final index = conversations.indexWhere((c) => c.id == conversationId);

    if (index == -1) {
      throw StateError('Conversation $conversationId not found');
    }

    final message = SachetaMessage(
      id: _uuid.v4(),
      role: role,
      content: content,
    );

    final updatedMessages = [...conversations[index].messages, message];
    final updated = conversations[index].copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    conversations[index] = updated;
    await _persistConversations(conversations);

    return updated;
  }

  /// Get the most recent conversation, or null.
  Future<SachetaConversation?> getLatestConversation() async {
    final conversations = await loadConversations();
    return conversations.isEmpty ? null : conversations.first;
  }

  /// Get conversation by id.
  Future<SachetaConversation?> getConversation(String id) async {
    final conversations = await loadConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Delete a conversation by id.
  Future<void> deleteConversation(String id) async {
    final conversations = await loadConversations();
    conversations.removeWhere((c) => c.id == id);
    await _persistConversations(conversations);
  }

  Future<void> _persistConversations(
    List<SachetaConversation> conversations,
  ) async {
    _cache = conversations;
    final f = await _file;
    final jsonStr = conversations.map((c) => c.toJson()).toList();
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonStr));
  }

  // ── Memory (long-term AI memory, separate from conversation history) ──

  /// Load Sacheta's long-term memory.
  Future<Map<String, dynamic>> loadMemory() async {
    if (_memoryCache != null) return _memoryCache!;

    final f = await _memoryFile;
    if (!await f.exists()) {
      _memoryCache = {};
      return _memoryCache!;
    }

    final raw = await f.readAsString();
    _memoryCache = json.decode(raw) as Map<String, dynamic>;
    return _memoryCache!;
  }

  /// Update Sacheta's long-term memory.
  Future<void> updateMemory(Map<String, dynamic> memory) async {
    _memoryCache = memory;
    final f = await _memoryFile;
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(memory));
  }
}
