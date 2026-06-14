class VoiceNote {
  final String id;
  final String fileName;
  final String? description;
  final String? audioUrl;
  final double? duration;
  final int? fileSize;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VoiceNote({
    required this.id,
    required this.fileName,
    this.description,
    this.audioUrl,
    this.duration,
    this.fileSize,
    this.createdAt,
    this.updatedAt,
  });

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      fileName:
          json['fileName']?.toString() ?? json['FileName']?.toString() ?? '',
      description: json['description']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      duration: (json['duration'] as num?)?.toDouble(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      if (description != null) 'description': description,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (duration != null) 'duration': duration,
      if (fileSize != null) 'fileSize': fileSize,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  VoiceNote copyWith({
    String? id,
    String? fileName,
    String? description,
    String? audioUrl,
    double? duration,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
