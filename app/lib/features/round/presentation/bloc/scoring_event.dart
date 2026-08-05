import 'package:equatable/equatable.dart';

sealed class ScoringEvent extends Equatable {
  const ScoringEvent();

  @override
  List<Object?> get props => [];
}

final class ScoringStarted extends ScoringEvent {
  const ScoringStarted({
    required this.gameId,
    required this.roundNumber,
  });

  final String gameId;
  final int roundNumber;

  @override
  List<Object?> get props => [gameId, roundNumber];
}

final class TrickValueChanged extends ScoringEvent {
  const TrickValueChanged(this.value);

  final int value;

  @override
  List<Object?> get props => [value];
}

final class TricksConfirmed extends ScoringEvent {
  const TricksConfirmed();
}

final class TricksEditActivated extends ScoringEvent {
  const TricksEditActivated(this.playerId);

  final String playerId;

  @override
  List<Object?> get props => [playerId];
}

final class TricksEditCancelled extends ScoringEvent {
  const TricksEditCancelled();
}

final class TricksUpdated extends ScoringEvent {
  const TricksUpdated({
    required this.playerId,
    required this.newTricks,
  });

  final String playerId;
  final int newTricks;

  @override
  List<Object?> get props => [playerId, newTricks];
}

final class CloseRoundRequested extends ScoringEvent {
  const CloseRoundRequested();
}
