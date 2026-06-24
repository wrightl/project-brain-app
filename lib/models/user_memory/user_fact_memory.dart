/// A learned fact stored for the user.
class UserFactMemory {
  final String id;
  final String content;
  final String category;
  final String status;
  final DateTime createdAt;
  final bool isPinned;

  UserFactMemory({
    required this.id,
    required this.content,
    required this.category,
    required this.status,
    required this.createdAt,
    this.isPinned = false,
  });

  factory UserFactMemory.fromJson(Map<String, dynamic> json) {
    return UserFactMemory(
      id: json['id'] as String,
      content: json['content'] as String,
      category: json['category'] as String? ?? 'general',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  UserFactMemory copyWith({bool? isPinned}) {
    return UserFactMemory(
      id: id,
      content: content,
      category: category,
      status: status,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
