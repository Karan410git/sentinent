import 'sacheta_message.dart';

/// A conversation between the user and Sacheta AI companion.
class SachetaConversation {
  SachetaConversation({
    required this.id,
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final List<SachetaMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The latest message in the conversation, or null.
  SachetaMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  /// A short preview of the conversation for history lists.
  String get preview {
    if (messages.isEmpty) return 'New conversation';
    final last = messages.last.content;
    return last.length > 60 ? '${last.substring(0, 60)}...' : last;
  }

  SachetaConversation copyWith({
    List<SachetaMessage>? messages,
    DateTime? updatedAt,
  }) {
    return SachetaConversation(
      id: id,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SachetaConversation.fromJson(Map<String, dynamic> json) {
    return SachetaConversation(
      id: json['id'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((m) => SachetaMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
