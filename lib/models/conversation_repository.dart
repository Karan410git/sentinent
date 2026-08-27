import 'package:supabase_flutter/supabase_flutter.dart';

import 'sacheta_conversation.dart';
import 'sacheta_message.dart';

/// Persistence for Sacheta conversations and memory using Supabase.
/// Supabase is the single source of truth. RLS enforces per-user isolation.
class ConversationRepository {
  ConversationRepository._();

  static final ConversationRepository instance = ConversationRepository._();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ── Conversations ──────────────────────────────────────────────

  /// Load all conversations for the current user with their messages,
  /// most recently updated first.
  Future<List<SachetaConversation>> loadConversations() async {
    final userId = _userId;
    if (userId == null) return [];

    // Load conversations.
    final convData = await _client
        .from('conversations')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    final conversations = <SachetaConversation>[];

    for (final convRow in convData as List<dynamic>) {
      final convMap = convRow as Map<String, dynamic>;
      final convId = convMap['id'] as String;

      // Load messages for this conversation.
      final msgData = await _client
          .from('messages')
          .select()
          .eq('conversation_id', convId)
          .order('created_at', ascending: true);

      final messages = (msgData as List<dynamic>)
          .map((m) => SachetaMessage.fromSupabase(m as Map<String, dynamic>))
          .toList();

      conversations.add(
        SachetaConversation(
          id: convId,
          messages: messages,
          createdAt: convMap['created_at'] != null
              ? DateTime.parse(convMap['created_at'] as String)
              : DateTime.now(),
          updatedAt: convMap['updated_at'] != null
              ? DateTime.parse(convMap['updated_at'] as String)
              : DateTime.now(),
        ),
      );
    }

    return conversations;
  }

  /// Create a new conversation and return it.
  Future<SachetaConversation> createConversation() async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('No authenticated user');
    }

    final data = await _client
        .from('conversations')
        .insert({'user_id': userId})
        .select()
        .single();

    return SachetaConversation(
      id: data['id'] as String,
      messages: [],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Add a message to a conversation and persist.
  Future<SachetaConversation> addMessage(
    String conversationId, {
    required String role,
    required String content,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('No authenticated user');
    }

    // Insert message.
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'content': content,
    });

    // Update conversation's updated_at.
    await _client
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    // Reload full conversation.
    return _loadConversation(conversationId);
  }

  /// Load a single conversation with all its messages.
  Future<SachetaConversation> _loadConversation(String conversationId) async {
    final convData = await _client
        .from('conversations')
        .select()
        .eq('id', conversationId)
        .single();

    final msgData = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    final messages = (msgData as List<dynamic>)
        .map((m) => SachetaMessage.fromSupabase(m as Map<String, dynamic>))
        .toList();

    return SachetaConversation(
      id: conversationId,
      messages: messages,
      createdAt: convData['created_at'] != null
          ? DateTime.parse(convData['created_at'] as String)
          : DateTime.now(),
      updatedAt: convData['updated_at'] != null
          ? DateTime.parse(convData['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Get the most recent conversation, or null.
  Future<SachetaConversation?> getLatestConversation() async {
    final conversations = await loadConversations();
    return conversations.isEmpty ? null : conversations.first;
  }

  /// Get conversation by id.
  Future<SachetaConversation?> getConversation(String id) async {
    try {
      return await _loadConversation(id);
    } catch (_) {
      return null;
    }
  }

  /// Delete a conversation by id (messages cascade-delete via FK).
  Future<void> deleteConversation(String id) async {
    await _client.from('conversations').delete().eq('id', id);
  }

  // ── Memory (long-term AI memory) ────────────────────────────

  /// Load Sacheta's long-term memory from Supabase (per user).
  Future<Map<String, dynamic>> loadMemory() async {
    final userId = _userId;
    if (userId == null) return {};

    try {
      final data = await _client
          .from('memories')
          .select('content')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null || data['content'] == null) return {};
      return Map<String, dynamic>.from(data['content'] as Map);
    } catch (_) {
      return {};
    }
  }

  /// Upsert Sacheta's long-term memory in Supabase (per user).
  Future<void> updateMemory(Map<String, dynamic> memory) async {
    final userId = _userId;
    if (userId == null) return;

    await _client.from('memories').upsert({
      'user_id': userId,
      'content': memory,
    }, onConflict: 'user_id');
  }
}
