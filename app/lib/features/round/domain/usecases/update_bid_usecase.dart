import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/round/domain/services/dealer_restriction_validator.dart';

class UpdateBidUseCase {
  UpdateBidUseCase(
    this._roundRepository, {
    DealerRestrictionValidator? validator,
  }) : _validator = validator ?? const DealerRestrictionValidator();

  final RoundRepository _roundRepository;
  final DealerRestrictionValidator _validator;

  Future<Round> call({
    required Round round,
    required String playerId,
    required int newBid,
  }) async {
    if (round.status != RoundStatus.bidding) {
      throw StateError('Bids can only be updated while the round is bidding');
    }

    if (!round.bids.containsKey(playerId)) {
      throw StateError('Player has not submitted a bid: $playerId');
    }

    if (newBid < 0 || newBid > round.cardsInRound) {
      throw ArgumentError(
        'Bid must be between 0 and ${round.cardsInRound}, got $newBid',
      );
    }

    if (playerId == round.dealerPlayerId) {
      final bidsBeforeDealer = Map<String, int>.from(round.bids)
        ..remove(round.dealerPlayerId);
      final forbiddenBid = _validator.forbiddenBidForDealer(
        cardsInRound: round.cardsInRound,
        bidsBeforeDealer: bidsBeforeDealer,
      );
      if (_validator.isForbiddenBid(bid: newBid, forbiddenBid: forbiddenBid)) {
        throw StateError(
          'Dealer cannot bid $newBid because the total would equal '
          '${round.cardsInRound} tricks',
        );
      }
    }

    final updatedBids = Map<String, int>.from(round.bids)..[playerId] = newBid;
    return _roundRepository.updateRound(round.copyWith(bids: updatedBids));
  }
}
