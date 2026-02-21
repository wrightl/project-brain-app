class User {
  final String id;
  final String email;
  final String name;
  final String? nickname;
  final String? picture;
  final bool isOnboarded;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Onboarding fields
  final String? fullName;
  final String? preferredPronoun;
  final String? doB; // Date of birth as ISO string
  final List<String>? neurodiverseTraits;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    this.picture,
    required this.isOnboarded,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.fullName,
    this.preferredPronoun,
    this.doB,
    this.neurodiverseTraits,
  });

  bool get hasImage => picture != null && picture!.isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['fullName']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      picture: json['picture']?.toString(),
      isOnboarded: json['isOnboarded'] == true,
      bio: json['bio']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      fullName: json['fullName']?.toString(),
      preferredPronoun: json['preferredPronoun']?.toString(),
      doB: json['doB']?.toString(),
      neurodiverseTraits: json['neurodiverseTraits'] is List
          ? List<String>.from(json['neurodiverseTraits'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'nickname': nickname,
      'picture': picture,
      'isOnboarded': isOnboarded,
      'bio': bio,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'fullName': fullName,
      'preferredPronoun': preferredPronoun,
      'doB': doB,
      'neurodiverseTraits': neurodiverseTraits,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? nickname,
    String? picture,
    bool? isOnboarded,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? preferredPronoun,
    String? doB,
    List<String>? neurodiverseTraits,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      picture: picture ?? this.picture,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      preferredPronoun: preferredPronoun ?? this.preferredPronoun,
      doB: doB ?? this.doB,
      neurodiverseTraits: neurodiverseTraits ?? this.neurodiverseTraits,
    );
  }
}
