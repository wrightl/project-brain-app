import 'package:projectbrain/models/journal/system_tag_field_definition.dart';

/// System (suggested) tag from catalog with field definitions.
class SystemTag {
  final String id;
  final String key;
  final String name;
  final String? description;
  final List<SystemTagFieldDefinition> fieldDefinitions;

  SystemTag({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    this.fieldDefinitions = const [],
  });

  factory SystemTag.fromJson(Map<String, dynamic> json) {
    return SystemTag(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      fieldDefinitions: json['fieldDefinitions'] != null
          ? (json['fieldDefinitions'] as List<dynamic>)
              .map((e) =>
                  SystemTagFieldDefinition.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      if (description != null) 'description': description,
      'fieldDefinitions': fieldDefinitions.map((e) => e.toJson()).toList(),
    };
  }
}
