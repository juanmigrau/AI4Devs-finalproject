import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';

/// Reverts a closed round back to [RoundStatus.playing] so tricks can be
/// re-entered. Clears tricks and scoresDelta, and subtracts the round's
/// scoresDelta from each player's totalScore.
class RevertRoundToPlayingUseCase {
  const RevertRoundToPlayingUseCase(
    this._gameRepository,
    this._roundRepository,
  );

  final GameRepository _gameRepository;
  final RoundRepository _roundRepository;

  Future<Round> call({
    required String gameId,
    required int roundNumber,
  }) async {
    final game = await _gameRepository.getGameById(gameId);
    if (game == null) {
      throw StateError('Game not found: $gameId');
    }

    final round = await _roundRepository.getRoundByGameAndNumber(
      gameId,
      roundNumber,
    );
    if (round == null) {
      throw StateError('Round not found: $gameId/$roundNumber');
    }

    if (round.status != RoundStatus.closed) {
      throw StateError(
        'Round cannot be reverted to playing from status ${round.status}',
      );
    }

    final delta = round.scoresDelta ?? const <String, int>{};
    final updatedPlayers = game.players
        .map(
          (player) => player.copyWith(
            totalScore: player.totalScore - (delta[player.id] ?? 0),
          ),
        )
        .toList();

    final reopenedRound = Round(
      id: round.id,
      gameId: round.gameId,
      roundNumber: round.roundNumber,
      cardsInRound: round.cardsInRound,
      dealerPlayerId: round.dealerPlayerId,
      status: RoundStatus.playing,
      bids: round.bids,
      tricks: const {},
      scoresDelta: const {},
      createdAt: round.createdAt,
      closedAt: null,
    );

    return _gameRepository.repeatRoundAndRevertScores(
      resetRound: reopenedRound,
      updatedPlayers: updatedPlayers,
    );
  }
}
