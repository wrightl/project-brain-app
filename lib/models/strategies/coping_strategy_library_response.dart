import 'package:projectbrain/models/strategies/coping_strategy_library_item.dart';

/// Response from GET /strategies/library.
class CopingStrategyLibraryResponse {
  final List<CopingStrategyLibraryItem> items;

  CopingStrategyLibraryResponse({required this.items});

  factory CopingStrategyLibraryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return CopingStrategyLibraryResponse(
      items: list
          .map((e) =>
              CopingStrategyLibraryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
