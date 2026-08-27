import 'dart:convert';

import 'package:http/http.dart' as http;

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
  static const _baseUrl = 'http://192.168.0.106:3000';

  // ── Public API ───────────────────────────────────────────────

  /// Generate Sacheta's response to a conversation.
  ///
  /// Throws [AIProviderException] on backend/provider errors.
  static Future<String> respond({
    required String conversationId,
    required List<SachetaMessage> messages,
  }) async {
    final languageStyle = AIConfig.instance.languageStyle;
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      final response = await http.post(
        Uri.parse('$_baseUrl/api/sacheta/respond'),
        headers: headers,
        body: jsonEncode({
          'conversationId': conversationId,
          'messages': messages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
          'languageStyle': languageStyle,
        }),
      );

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
      final headers = <String, String>{'Content-Type': 'application/json'};

      await http.post(
        Uri.parse('$_baseUrl/api/sacheta/extract-memory'),
        headers: headers,
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
