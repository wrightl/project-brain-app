import 'package:projectbrain/models/strategies/create_coping_strategy_request.dart';

/// A suggested strategy from the strategies chat (not persisted as-is).
/// When saving, map to CreateCopingStrategyRequest (title, description, iconKey only).
class SuggestedStrategy {
  final String title;
  final String description;
  final String? iconKey;
  final String? articleUrl;

  SuggestedStrategy({
    required this.title,
    required this.description,
    this.iconKey,
    this.articleUrl,
  });

  factory SuggestedStrategy.fromJson(Map<String, dynamic> json) {
    return SuggestedStrategy(
      title: json['title'] as String,
      description: json['description'] as String,
      iconKey: json['iconKey'] as String?,
      articleUrl: json['articleUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (iconKey != null) 'iconKey': iconKey,
      if (articleUrl != null) 'articleUrl': articleUrl,
    };
  }

  /// Convert to create request for POST /strategies (no articleUrl).
  CreateCopingStrategyRequest toCreateRequest() {
    return CreateCopingStrategyRequest(
      title: title,
      description: description,
      iconKey: iconKey,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuggestedStrategy &&
        other.title == title &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(title, description);
}
