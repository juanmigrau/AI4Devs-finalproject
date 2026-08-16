import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  /// Returns the signed-in profile, or `null` if the user cancelled the picker.
  Future<UserProfile?> call() => _repository.signInWithGoogle();
}
