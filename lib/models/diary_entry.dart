/// A single diary entry backed by Supabase.
class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.content,
    this.title,
    this.mode = 'my_pages',
    this.pageDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String content;
  final String? title;
  final String mode;
  final String? pageDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry copyWith({String? content, String? title, DateTime? updatedAt}) {
    return DiaryEntry(
      id: id,
      content: content ?? this.content,
      title: title ?? this.title,
      mode: mode,
      pageDate: pageDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'title': title,
    'mode': mode,
    'pageDate': pageDate,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      title: json['title'] as String?,
      mode: json['mode'] as String? ?? 'my_pages',
      pageDate: json['pageDate'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create from a Supabase row.
  factory DiaryEntry.fromSupabase(Map<String, dynamic> row) {
    return DiaryEntry(
      id: row['id'] as String,
      content: (row['content'] as String?) ?? '',
      title: row['title'] as String?,
      mode: (row['mode'] as String?) ?? 'my_pages',
      pageDate: row['page_date'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
