/// A saved coping strategy in the user's library.
class CopingStrategyLibraryItem {
  final String id;
  final String title;
  final String description;
  final String? iconKey;
  final int? rating;
  final DateTime savedAt;

  CopingStrategyLibraryItem({
    required this.id,
    required this.title,
    required this.description,
    this.iconKey,
    this.rating,
    required this.savedAt,
  });

  factory CopingStrategyLibraryItem.fromJson(Map<String, dynamic> json) {
    return CopingStrategyLibraryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconKey: json['iconKey'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (iconKey != null) 'iconKey': iconKey,
      if (rating != null) 'rating': rating,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  CopingStrategyLibraryItem copyWith({
    String? id,
    String? title,
    String? description,
    String? iconKey,
    int? rating,
    DateTime? savedAt,
  }) {
    return CopingStrategyLibraryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      rating: rating ?? this.rating,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}
