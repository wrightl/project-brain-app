import 'package:dartz/dartz.dart';
import 'package:projectbrain/core/errors/failures.dart';
import 'package:projectbrain/features/authentication/domain/entities/user_entity.dart';
import 'package:projectbrain/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for logging in a user
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    return await repository.login();
  }
}
