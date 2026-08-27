/// Errors thrown by the AI backend when a request fails.
class AIProviderException implements Exception {
  const AIProviderException({
    required this.message,
    this.statusCode,
    this.provider,
  });

  final String message;
  final int? statusCode;
  final String? provider;

  @override
  String toString() {
    final prefix = provider != null ? '[$provider] ' : '';
    final code = statusCode != null ? ' (HTTP $statusCode)' : '';
    return '$prefix$message$code';
  }
}
