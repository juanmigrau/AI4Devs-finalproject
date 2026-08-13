import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';

class UpdateDisplayNameUseCase {
  const UpdateDisplayNameUseCase(this._repository);

  final AuthRepository _repository;

  static const int maxLength = 20;

  Future<UserProfile> call(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure('El nombre es obligatorio');
    }
    if (trimmed.length > maxLength) {
      throw const ValidationFailure(
        'El nombre no puede superar los 20 caracteres',
      );
    }
    return _repository.updateDisplayName(trimmed);
  }
}
