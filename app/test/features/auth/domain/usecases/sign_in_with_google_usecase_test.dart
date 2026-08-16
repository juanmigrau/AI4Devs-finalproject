import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sign_in_with_google_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  group('SignInWithGoogleUseCase', () {
    late MockAuthRepository repository;
    late SignInWithGoogleUseCase useCase;

    final profile = UserProfile(
      uid: 'uid-google',
      displayName: 'Ana Google',
      email: 'ana@gmail.com',
      photoUrl: 'https://example.com/photo.jpg',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    setUp(() {
      repository = MockAuthRepository();
      useCase = SignInWithGoogleUseCase(repository);
    });

    test('returns profile when repository signs in', () async {
      when(repository.signInWithGoogle()).thenAnswer((_) async => profile);

      final result = await useCase();

      expect(result, profile);
      verify(repository.signInWithGoogle()).called(1);
    });

    test('returns null when user cancels Google picker', () async {
      when(repository.signInWithGoogle()).thenAnswer((_) async => null);

      final result = await useCase();

      expect(result, isNull);
      verify(repository.signInWithGoogle()).called(1);
    });
  });
}
