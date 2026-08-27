/// A single message within a Sacheta conversation.
class SachetaMessage {
  SachetaMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String role; // 'user' or 'sacheta'
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SachetaMessage.fromJson(Map<String, dynamic> json) {
    return SachetaMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
