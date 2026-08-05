import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';

/// Reverts a round from [RoundStatus.playing] back to [RoundStatus.bidding]
/// so the user can edit existing bids. Preserves [Round.bids] and all other
/// fields; only the status changes.
class RevertRoundToBiddingUseCase {
  const RevertRoundToBiddingUseCase(this._roundRepository);

  final RoundRepository _roundRepository;

  Future<Round> call({
    required String gameId,
    required int roundNumber,
  }) async {
    final round = await _roundRepository.getRoundByGameAndNumber(
      gameId,
      roundNumber,
    );
    if (round == null) {
      throw StateError('Round not found: $gameId/$roundNumber');
    }

    if (round.status == RoundStatus.bidding) {
      return round;
    }

    if (round.status != RoundStatus.playing) {
      throw StateError(
        'Round cannot be reverted to bidding from status ${round.status}',
      );
    }

    return _roundRepository.updateRound(
      round.copyWith(status: RoundStatus.bidding),
    );
  }
}
