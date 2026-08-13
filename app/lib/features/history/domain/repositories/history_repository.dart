import '../entities/game_detail.dart';
import '../entities/game_history_item.dart';
import '../entities/game_history_load_result.dart';
import '../entities/game_history_source.dart';

abstract class HistoryRepository {
  Future<GameHistoryLoadResult> getGameHistory();

  Future<List<GameHistoryItem>> getRecentFinishedGames({int limit = 3});

  Future<GameDetail> getGameDetail({
    required String gameId,
    required GameHistorySource source,
  });

  Future<void> deleteLocalGame(String gameId);

  Future<void> hideCloudGame(String gameId);
}
