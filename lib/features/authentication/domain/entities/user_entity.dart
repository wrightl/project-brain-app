import 'package:equatable/equatable.dart';

/// Domain entity for authenticated user
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? nickname;
  final String? picture;
  final String? bio;
  final bool isOnboarded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    this.picture,
    this.bio,
    required this.isOnboarded,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        nickname,
        picture,
        bio,
        isOnboarded,
        createdAt,
        updatedAt,
      ];
}
