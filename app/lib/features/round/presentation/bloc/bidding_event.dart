import 'package:equatable/equatable.dart';

sealed class BiddingEvent extends Equatable {
  const BiddingEvent();

  @override
  List<Object?> get props => [];
}

final class BiddingStarted extends BiddingEvent {
  const BiddingStarted({
    required this.gameId,
    required this.roundNumber,
  });

  final String gameId;
  final int roundNumber;

  @override
  List<Object?> get props => [gameId, roundNumber];
}

final class BidValueChanged extends BiddingEvent {
  const BidValueChanged(this.bid);

  final int bid;

  @override
  List<Object?> get props => [bid];
}

final class BidConfirmed extends BiddingEvent {
  const BidConfirmed();
}

final class BidEditActivated extends BiddingEvent {
  const BidEditActivated(this.playerId);

  final String playerId;

  @override
  List<Object?> get props => [playerId];
}

final class BidEditCancelled extends BiddingEvent {
  const BidEditCancelled();
}

final class BidUpdated extends BiddingEvent {
  const BidUpdated({required this.playerId, required this.newBid});

  final String playerId;
  final int newBid;

  @override
  List<Object?> get props => [playerId, newBid];
}

final class CloseBiddingRequested extends BiddingEvent {
  const CloseBiddingRequested();
}
