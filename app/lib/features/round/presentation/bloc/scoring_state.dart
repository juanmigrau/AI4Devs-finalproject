import 'package:equatable/equatable.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';

sealed class ScoringState extends Equatable {
  const ScoringState();

  @override
  List<Object?> get props => [];
}

final class ScoringInitial extends ScoringState {
  const ScoringInitial();
}

final class ScoringLoading extends ScoringState {
  const ScoringLoading();
}

final class ScoringFailure extends ScoringState {
  const ScoringFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ScoringLoaded extends ScoringState {
  const ScoringLoaded({
    required this.game,
    required this.round,
    required this.scoringOrder,
    required this.confirmedTricks,
    required this.currentPlayerId,
    required this.draftTrick,
    required this.tricksSum,
    required this.remainingTricks,
    required this.canConfirmTrick,
    required this.canConfirm,
    this.editingPlayerId,
    this.validationMessage,
    this.isClosing = false,
  });

  final Game game;
  final Round round;
  final List<String> scoringOrder;
  final Map<String, int> confirmedTricks;
  final String? currentPlayerId;
  final int draftTrick;
  final int tricksSum;
  final int remainingTricks;
  final bool canConfirmTrick;
  final bool canConfirm;
  final String? editingPlayerId;
  final String? validationMessage;
  final bool isClosing;

  ScoringLoaded copyWith({
    Game? game,
    Round? round,
    List<String>? scoringOrder,
    Map<String, int>? confirmedTricks,
    String? currentPlayerId,
    bool clearCurrentPlayerId = false,
    int? draftTrick,
    int? tricksSum,
    int? remainingTricks,
    bool? canConfirmTrick,
    bool? canConfirm,
    String? editingPlayerId,
    bool clearEditingPlayerId = false,
    String? Function()? validationMessage,
    bool? isClosing,
  }) {
    return ScoringLoaded(
      game: game ?? this.game,
      round: round ?? this.round,
      scoringOrder: scoringOrder ?? this.scoringOrder,
      confirmedTricks: confirmedTricks ?? this.confirmedTricks,
      currentPlayerId: clearCurrentPlayerId
          ? null
          : (currentPlayerId ?? this.currentPlayerId),
      draftTrick: draftTrick ?? this.draftTrick,
      tricksSum: tricksSum ?? this.tricksSum,
      remainingTricks: remainingTricks ?? this.remainingTricks,
      canConfirmTrick: canConfirmTrick ?? this.canConfirmTrick,
      canConfirm: canConfirm ?? this.canConfirm,
      editingPlayerId: clearEditingPlayerId
          ? null
          : (editingPlayerId ?? this.editingPlayerId),
      validationMessage: validationMessage != null
          ? validationMessage()
          : this.validationMessage,
      isClosing: isClosing ?? this.isClosing,
    );
  }

  @override
  List<Object?> get props => [
        game,
        round,
        scoringOrder,
        confirmedTricks,
        currentPlayerId,
        draftTrick,
        tricksSum,
        remainingTricks,
        canConfirmTrick,
        canConfirm,
        editingPlayerId,
        validationMessage,
        isClosing,
      ];
}

final class ScoringNavigateToResult extends ScoringState {
  const ScoringNavigateToResult({
    required this.gameId,
    required this.roundNumber,
  });

  final String gameId;
  final int roundNumber;

  @override
  List<Object?> get props => [gameId, roundNumber];
}
