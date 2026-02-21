/// Request body for POST /strategies.
class CreateCopingStrategyRequest {
  final String title;
  final String description;
  final String? iconKey;

  CreateCopingStrategyRequest({
    required this.title,
    required this.description,
    this.iconKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (iconKey != null) 'iconKey': iconKey,
    };
  }
}
