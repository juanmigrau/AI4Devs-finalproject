import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:la_pocha/features/history/domain/repositories/history_repository.dart';

class DeleteAccountUseCase {
  const DeleteAccountUseCase({
    required this._authRepository,
    required this._favoriteRepository,
    required this._historyRepository,
  });

  final AuthRepository _authRepository;
  final FavoriteRepository _favoriteRepository;
  final HistoryRepository _historyRepository;

  Future<void> call({String? password}) async {
    await _authRepository.deleteAccount(password: password);
    await _favoriteRepository.clearAll();
    await _historyRepository.clearHiddenGames();
  }
}
