/// Field definition for a system tag (e.g. Sleep quality, Hours slept).
class SystemTagFieldDefinition {
  final String id;
  final String fieldKey;
  final String label;
  final String inputType; // text | textarea | number | rating | select | time
  final bool required;
  final int fieldOrder;
  final String? placeholder;
  final String? hint;
  final List<String>? options;
  final num? minValue;
  final num? maxValue;
  final num? stepValue;

  SystemTagFieldDefinition({
    required this.id,
    required this.fieldKey,
    required this.label,
    required this.inputType,
    this.required = false,
    this.fieldOrder = 0,
    this.placeholder,
    this.hint,
    this.options,
    this.minValue,
    this.maxValue,
    this.stepValue,
  });

  factory SystemTagFieldDefinition.fromJson(Map<String, dynamic> json) {
    return SystemTagFieldDefinition(
      id: json['id'] as String,
      fieldKey: json['fieldKey'] as String,
      label: json['label'] as String,
      inputType: (json['inputType'] ?? 'text') as String,
      required: json['required'] as bool? ?? false,
      fieldOrder: (json['fieldOrder'] as num?)?.toInt() ?? 0,
      placeholder: json['placeholder'] as String?,
      hint: json['hint'] as String?,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      minValue: json['minValue'] != null
          ? num.tryParse(json['minValue'].toString())
          : null,
      maxValue: json['maxValue'] != null
          ? num.tryParse(json['maxValue'].toString())
          : null,
      stepValue: json['stepValue'] != null
          ? num.tryParse(json['stepValue'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fieldKey': fieldKey,
      'label': label,
      'inputType': inputType,
      'required': required,
      'fieldOrder': fieldOrder,
      if (placeholder != null) 'placeholder': placeholder,
      if (hint != null) 'hint': hint,
      if (options != null) 'options': options,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (stepValue != null) 'stepValue': stepValue,
    };
  }
}
