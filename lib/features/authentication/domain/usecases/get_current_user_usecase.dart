import 'package:dartz/dartz.dart';
import 'package:projectbrain/core/errors/failures.dart';
import 'package:projectbrain/features/authentication/domain/entities/user_entity.dart';
import 'package:projectbrain/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for getting the current authenticated user
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    return await repository.getCurrentUser();
  }
}
