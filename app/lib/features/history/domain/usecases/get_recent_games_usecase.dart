import '../entities/game_history_item.dart';
import '../repositories/history_repository.dart';

class GetRecentGamesUseCase {
  const GetRecentGamesUseCase(this._repository);

  final HistoryRepository _repository;

  Stream<List<GameHistoryItem>> call({int limit = 3}) =>
      _repository.watchRecentFinishedGames(limit: limit);
}
