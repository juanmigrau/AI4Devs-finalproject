import '../repositories/game_repository.dart';

class RevertGameToSetupUseCase {
  RevertGameToSetupUseCase(this._repository);

  final GameRepository _repository;

  Future<void> call(String gameId) {
    return _repository.revertGameToSetup(gameId);
  }
}
