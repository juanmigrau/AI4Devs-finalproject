import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/auth/domain/usecases/update_display_name_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'update_display_name_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  group('UpdateDisplayNameUseCase', () {
    late MockAuthRepository repository;
    late UpdateDisplayNameUseCase useCase;

    final profile = UserProfile(
      uid: 'uid-1',
      displayName: 'Nuevo',
      email: 'ana@example.com',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    setUp(() {
      repository = MockAuthRepository();
      useCase = UpdateDisplayNameUseCase(repository);
    });

    test('trims and updates display name', () async {
      when(repository.updateDisplayName('Nuevo')).thenAnswer((_) async => profile);

      final result = await useCase('  Nuevo  ');

      expect(result, profile);
      verify(repository.updateDisplayName('Nuevo')).called(1);
    });

    test('throws ValidationFailure when name is empty', () {
      expect(
        () => useCase('   '),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(repository.updateDisplayName(any));
    });

    test('throws ValidationFailure when name exceeds max length', () {
      expect(
        () => useCase('abcdefghijklmnopqrstu'),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(repository.updateDisplayName(any));
    });
  });
}
