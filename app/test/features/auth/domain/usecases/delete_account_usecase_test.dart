import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:la_pocha/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:la_pocha/features/history/domain/repositories/history_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'delete_account_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<FavoriteRepository>(),
  MockSpec<HistoryRepository>(),
])
void main() {
  group('DeleteAccountUseCase', () {
    late MockAuthRepository authRepository;
    late MockFavoriteRepository favoriteRepository;
    late MockHistoryRepository historyRepository;
    late DeleteAccountUseCase useCase;

    setUp(() {
      authRepository = MockAuthRepository();
      favoriteRepository = MockFavoriteRepository();
      historyRepository = MockHistoryRepository();
      useCase = DeleteAccountUseCase(
        authRepository: authRepository,
        favoriteRepository: favoriteRepository,
        historyRepository: historyRepository,
      );
    });

    test('deletes remote account then clears local account data', () async {
      when(
        authRepository.deleteAccount(password: anyNamed('password')),
      ).thenAnswer((_) async {});
      when(favoriteRepository.clearAll()).thenAnswer((_) async {});
      when(historyRepository.clearHiddenGames()).thenAnswer((_) async {});

      await useCase();

      verifyInOrder([
        authRepository.deleteAccount(),
        favoriteRepository.clearAll(),
        historyRepository.clearHiddenGames(),
      ]);
    });

    test('forwards password to the auth repository', () async {
      when(
        authRepository.deleteAccount(password: anyNamed('password')),
      ).thenAnswer((_) async {});
      when(favoriteRepository.clearAll()).thenAnswer((_) async {});
      when(historyRepository.clearHiddenGames()).thenAnswer((_) async {});

      await useCase(password: 'secret1');

      verify(authRepository.deleteAccount(password: 'secret1')).called(1);
    });

    test('does not clear local data when remote delete fails', () async {
      when(
        authRepository.deleteAccount(password: anyNamed('password')),
      ).thenThrow(const RequiresRecentLoginFailure());

      await expectLater(useCase(), throwsA(isA<RequiresRecentLoginFailure>()));

      verifyNever(favoriteRepository.clearAll());
      verifyNever(historyRepository.clearHiddenGames());
    });
  });
}
