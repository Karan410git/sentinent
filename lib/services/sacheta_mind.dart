import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sacheta_message.dart';
import 'ai_config.dart';
import 'ai_provider.dart';

/// The character brain of Sacheta.
///
/// Builds context (memory + conversation history) and calls the
/// backend endpoint. The backend handles Groq communication
/// and API key management — no credentials ever touch Flutter.
class SachetaMind {
  SachetaMind._();

  /// Backend base URL. Change for production deployment.
 static const _baseUrl = 'https://sentinent-kohl.vercel.app';
  /// Get the current Supabase access token for backend auth.
  static String? get _accessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  /// Build request headers with Authorization Bearer token.
  ///
  /// If no valid session exists, returns headers without Authorization
  /// and logs a warning. The backend will reject with 401.
  static Map<String, String> get _authHeaders {
    final token = _accessToken;

    if (token == null) {
      debugPrint(
        '[Sacheta Mind] ⚠ No access token available. '
        'User may need to re-authenticate.',
      );
      debugPrint(
        '[Sacheta Mind] currentSession: '
        '${Supabase.instance.client.auth.currentSession != null}',
      );
      debugPrint(
        '[Sacheta Mind] currentUser: '
        '${Supabase.instance.client.auth.currentUser?.id}',
      );
      return {
        'Content-Type': 'application/json',
      };
    }

    debugPrint(
      '[Sacheta Mind] Access token present, length: ${token.length}',
    );
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Public API ───────────────────────────────────────────────

  /// Generate Sacheta's response to a conversation.
  ///
  /// Throws [AIProviderException] on backend/provider errors.
  static Future<String> respond({
    required String conversationId,
    required List<SachetaMessage> messages,
  }) async {
    final languageStyle = AIConfig.instance.languageStyle;

    // Ensure we have a valid token before making the request.
    final token = _accessToken;
    if (token == null) {
      debugPrint(
        '[Sacheta Mind] BLOCKED: Cannot send request without access token.',
      );
      throw const AIProviderException(
        message:
            'Your session has drifted. Please close and reopen the pages, or sign in again.',
        statusCode: 401,
        provider: 'backend',
      );
    }

    try {
      debugPrint(
        '[Sacheta Mind] Sending request to $_baseUrl/api/sacheta/respond',
      );
      debugPrint('[Sacheta Mind] Token length: ${token.length}');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/sacheta/respond'),
        headers: _authHeaders,
        body: jsonEncode({
          'conversationId': conversationId,
          'messages': messages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
          'languageStyle': languageStyle,
        }),
      );

      debugPrint('[Sacheta Mind] Response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        debugPrint('[Sacheta Mind] ⚠ 401 from backend. Response: ${response.body}');
        throw const AIProviderException(
          message: 'Authentication required. Please sign in again.',
          statusCode: 401,
          provider: 'backend',
        );
      }

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final message = body['message'] as String? ?? 'Sacheta is unavailable.';
        throw AIProviderException(
          message: message,
          statusCode: response.statusCode,
          provider: 'backend',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['content'] as String;
    } catch (e) {
      if (e is AIProviderException) rethrow;

      // Network error, timeout, etc.
      throw const AIProviderException(
        message:
            'The pages are quiet tonight. I cannot seem to reach beyond them.',
        provider: 'backend',
      );
    }
  }

  /// Extract facts worth remembering from a conversation exchange.
  ///
  /// Runs as a lightweight background call after each response.
  /// The backend handles extraction — this is fire-and-forget.
  static Future<void> extractMemory({
    required String conversationId,
    required List<SachetaMessage> messages,
  }) async {
    try {
      final token = _accessToken;
      if (token == null) {
        debugPrint('[Sacheta Mind] Skipping memory extraction — no token.');
        return;
      }

      await http.post(
        Uri.parse('$_baseUrl/api/sacheta/extract-memory'),
        headers: _authHeaders,
        body: jsonEncode({
          'messages': messages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
        }),
      );
    } catch (_) {
      // Memory extraction is best-effort — never block the conversation.
    }
  }
}
