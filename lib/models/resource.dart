class Resource {
  final String id;
  final String fileName;

  Resource({
    required this.id,
    required this.fileName,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] ?? json['Id'] ?? '',
      fileName: json['fileName'] ?? json['FileName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
    };
  }

  Resource copyWith({
    String? id,
    String? fileName,
  }) {
    return Resource(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
    );
  }
}

