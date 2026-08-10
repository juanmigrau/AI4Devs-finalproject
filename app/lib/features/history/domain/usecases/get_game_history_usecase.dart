import '../entities/game_history_load_result.dart';
import '../repositories/history_repository.dart';

class GetGameHistoryUseCase {
  const GetGameHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<GameHistoryLoadResult> call() => _repository.getGameHistory();
}
