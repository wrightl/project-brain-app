import 'package:dartz/dartz.dart';
import 'package:projectbrain/core/errors/failures.dart';
import 'package:projectbrain/features/authentication/domain/entities/user_entity.dart';
import 'package:projectbrain/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for completing user onboarding
class CompleteOnboardingUseCase {
  final AuthRepository repository;

  CompleteOnboardingUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(
    Map<String, dynamic> onboardingData,
  ) async {
    return await repository.completeOnboarding(onboardingData);
  }
}
