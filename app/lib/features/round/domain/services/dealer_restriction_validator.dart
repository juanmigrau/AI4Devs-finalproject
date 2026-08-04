class DealerRestrictionValidator {
  const DealerRestrictionValidator();

  int partialBidSum(Map<String, int> bids) {
    return bids.values.fold(0, (sum, bid) => sum + bid);
  }

  int availableTricks({
    required int cardsInRound,
    required Map<String, int> bids,
  }) {
    return cardsInRound - partialBidSum(bids);
  }

  /// Forbidden dealer bid = cardsInRound - sum of other bids.
  /// Returns null when that value is negative (restriction cannot be violated).
  int? forbiddenBidForDealer({
    required int cardsInRound,
    required Map<String, int> bidsBeforeDealer,
  }) {
    final forbidden = availableTricks(
      cardsInRound: cardsInRound,
      bids: bidsBeforeDealer,
    );
    return forbidden >= 0 ? forbidden : null;
  }

  bool isForbiddenBid({
    required int bid,
    required int? forbiddenBid,
  }) {
    return forbiddenBid != null && bid == forbiddenBid;
  }

  bool canClose({
    required int cardsInRound,
    required Map<String, int> bids,
    required List<String> playerIds,
  }) {
    if (playerIds.any((playerId) => !bids.containsKey(playerId))) {
      return false;
    }

    return partialBidSum(bids) != cardsInRound;
  }
}
