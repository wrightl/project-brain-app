class VoiceNote {
  final String id;
  final String fileName;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VoiceNote({
    required this.id,
    required this.fileName,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      id: json['id'] ?? json['Id'] ?? '',
      fileName: json['fileName'] ?? json['FileName'] ?? '',
      description: json['description'] ?? json['Description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  VoiceNote copyWith({
    String? id,
    String? fileName,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

