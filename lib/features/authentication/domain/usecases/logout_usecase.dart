import 'package:dartz/dartz.dart';
import 'package:projectbrain/core/errors/failures.dart';
import 'package:projectbrain/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for logging out the current user
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, Unit>> call() async {
    return await repository.logout();
  }
}
