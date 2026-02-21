class Resource {
  final String id;
  final String fileName;
  final String? userId;
  final String? location;
  final int? sizeInBytes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isShared;

  Resource({
    required this.id,
    required this.fileName,
    this.userId,
    this.location,
    this.sizeInBytes,
    this.createdAt,
    this.updatedAt,
    this.isShared,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] ?? json['Id'] ?? '',
      fileName: json['fileName'] ?? json['FileName'] ?? '',
      userId: json['userId']?.toString(),
      location: json['location']?.toString(),
      sizeInBytes: (json['sizeInBytes'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isShared: json['isShared'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      if (userId != null) 'userId': userId,
      if (location != null) 'location': location,
      if (sizeInBytes != null) 'sizeInBytes': sizeInBytes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (isShared != null) 'isShared': isShared,
    };
  }

  Resource copyWith({
    String? id,
    String? fileName,
    String? userId,
    String? location,
    int? sizeInBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isShared,
  }) {
    return Resource(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isShared: isShared ?? this.isShared,
    );
  }
}

