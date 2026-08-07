import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/round/domain/services/bid_order_service.dart';
import 'package:la_pocha/features/round/domain/services/tricks_sum_validator.dart';
import 'package:la_pocha/features/round/domain/usecases/close_round_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/get_round_play_state_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/scoring_event.dart';
import 'package:la_pocha/features/round/presentation/bloc/scoring_state.dart';

class ScoringBloc extends Bloc<ScoringEvent, ScoringState> {
  ScoringBloc({
    required this._getRoundPlayState,
    required this._closeRound,
    BidOrderService? bidOrderService,
    TricksSumValidator? validator,
  }) : _bidOrderService = bidOrderService ?? const BidOrderService(),
       _validator = validator ?? const TricksSumValidator(),
       super(const ScoringInitial()) {
    on<ScoringStarted>(_onScoringStarted);
    on<TrickValueChanged>(_onTrickValueChanged);
    on<TricksConfirmed>(_onTricksConfirmed);
    on<TricksEditActivated>(_onTricksEditActivated);
    on<TricksEditCancelled>(_onTricksEditCancelled);
    on<TricksUpdated>(_onTricksUpdated);
    on<CloseRoundRequested>(_onCloseRoundRequested);
  }

  final GetRoundPlayStateUseCase _getRoundPlayState;
  final CloseRoundUseCase _closeRound;
  final BidOrderService _bidOrderService;
  final TricksSumValidator _validator;

  Future<void> _onScoringStarted(
    ScoringStarted event,
    Emitter<ScoringState> emit,
  ) async {
    emit(const ScoringLoading());
    try {
      final playState = await _getRoundPlayState(
        gameId: event.gameId,
        roundNumber: event.roundNumber,
      );
      final scoringOrder = _bidOrderService.biddingOrder(
        players: playState.game.players,
        dealerPlayerId: playState.round.dealerPlayerId,
      );
      final currentPlayerId = scoringOrder.isEmpty ? null : scoringOrder.first;
      final draftTrick = _defaultTrickForPlayer(
        playerId: currentPlayerId,
        bids: playState.round.bids,
        cardsInRound: playState.round.cardsInRound,
        confirmedTricks: const {},
      );

      emit(
        _buildLoadedState(
          game: playState.game,
          round: playState.round,
          scoringOrder: scoringOrder,
          confirmedTricks: const {},
          currentPlayerId: currentPlayerId,
          draftTrick: draftTrick,
        ),
      );
    } catch (error) {
      emit(ScoringFailure(message: mapExceptionToUserMessage(error)));
    }
  }

  void _onTrickValueChanged(
    TrickValueChanged event,
    Emitter<ScoringState> emit,
  ) {
    final current = state;
    if (current is! ScoringLoaded) {
      return;
    }
    if (current.editingPlayerId == null && current.currentPlayerId == null) {
      return;
    }
    if (event.value > current.draftTrick && !current.canAddMore) {
      return;
    }

    emit(
      _buildLoadedState(
        game: current.game,
        round: current.round,
        scoringOrder: current.scoringOrder,
        confirmedTricks: current.confirmedTricks,
        currentPlayerId: current.currentPlayerId,
        draftTrick: event.value,
        editingPlayerId: current.editingPlayerId,
      ),
    );
  }

  void _onTricksConfirmed(
    TricksConfirmed event,
    Emitter<ScoringState> emit,
  ) {
    final current = state;
    if (current is! ScoringLoaded ||
        current.editingPlayerId != null ||
        current.currentPlayerId == null ||
        !current.canConfirmTrick) {
      return;
    }

    final playerId = current.currentPlayerId!;
    final updatedTricks = Map<String, int>.from(current.confirmedTricks)
      ..[playerId] = current.draftTrick;

    final nextPlayerId = _nextUnconfirmedPlayer(
      scoringOrder: current.scoringOrder,
      confirmedTricks: updatedTricks,
    );
    final draftTrick = _defaultTrickForPlayer(
      playerId: nextPlayerId,
      bids: current.round.bids,
      cardsInRound: current.round.cardsInRound,
      confirmedTricks: updatedTricks,
    );

    emit(
      _buildLoadedState(
        game: current.game,
        round: current.round,
        scoringOrder: current.scoringOrder,
        confirmedTricks: updatedTricks,
        currentPlayerId: nextPlayerId,
        draftTrick: draftTrick,
      ),
    );
  }

  void _onTricksEditActivated(
    TricksEditActivated event,
    Emitter<ScoringState> emit,
  ) {
    final current = state;
    if (current is! ScoringLoaded) {
      return;
    }
    if (!current.confirmedTricks.containsKey(event.playerId)) {
      return;
    }

    emit(
      _buildLoadedState(
        game: current.game,
        round: current.round,
        scoringOrder: current.scoringOrder,
        confirmedTricks: current.confirmedTricks,
        currentPlayerId: current.currentPlayerId,
        draftTrick: current.confirmedTricks[event.playerId]!,
        editingPlayerId: event.playerId,
      ),
    );
  }

  void _onTricksEditCancelled(
    TricksEditCancelled event,
    Emitter<ScoringState> emit,
  ) {
    final current = state;
    if (current is! ScoringLoaded || current.editingPlayerId == null) {
      return;
    }

    final draftTrick = _defaultTrickForPlayer(
      playerId: current.currentPlayerId,
      bids: current.round.bids,
      cardsInRound: current.round.cardsInRound,
      confirmedTricks: current.confirmedTricks,
    );

    emit(
      _buildLoadedState(
        game: current.game,
        round: current.round,
        scoringOrder: current.scoringOrder,
        confirmedTricks: current.confirmedTricks,
        currentPlayerId: current.currentPlayerId,
        draftTrick: draftTrick,
      ),
    );
  }

  void _onTricksUpdated(
    TricksUpdated event,
    Emitter<ScoringState> emit,
  ) {
    final current = state;
    if (current is! ScoringLoaded ||
        current.editingPlayerId != event.playerId ||
        !current.canConfirmTrick) {
      return;
    }

    final updatedTricks = Map<String, int>.from(current.confirmedTricks)
      ..[event.playerId] = event.newTricks;

    final draftTrick = _defaultTrickForPlayer(
      playerId: current.currentPlayerId,
      bids: current.round.bids,
      cardsInRound: current.round.cardsInRound,
      confirmedTricks: updatedTricks,
    );

    emit(
      _buildLoadedState(
        game: current.game,
        round: current.round,
        scoringOrder: current.scoringOrder,
        confirmedTricks: updatedTricks,
        currentPlayerId: current.currentPlayerId,
        draftTrick: draftTrick,
      ),
    );
  }

  Future<void> _onCloseRoundRequested(
    CloseRoundRequested event,
    Emitter<ScoringState> emit,
  ) async {
    final current = state;
    if (current is! ScoringLoaded || !current.canConfirm || current.isClosing) {
      return;
    }

    emit(current.copyWith(isClosing: true, validationMessage: () => null));
    try {
      await _closeRound(
        gameId: current.game.id,
        round: current.round,
        players: current.game.players,
        tricks: current.confirmedTricks,
      );
      emit(
        ScoringNavigateToResult(
          gameId: current.game.id,
          roundNumber: current.round.roundNumber,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isClosing: false,
          validationMessage: () => mapExceptionToUserMessage(error),
        ),
      );
    }
  }

  /// Default tricks for a pending player: min(bid, remaining after confirmed).
  /// Confirmed players are never recalculated; only pending drafts use this.
  int _defaultTrickForPlayer({
    required String? playerId,
    required Map<String, int> bids,
    required int cardsInRound,
    required Map<String, int> confirmedTricks,
  }) {
    if (playerId == null) {
      return 0;
    }
    final remaining =
        cardsInRound - _validator.partialTricksSum(confirmedTricks);
    final cappedRemaining = math.max(0, remaining);
    final bid = bids[playerId] ?? 0;
    return math.min(bid, cappedRemaining);
  }

  String? _nextUnconfirmedPlayer({
    required List<String> scoringOrder,
    required Map<String, int> confirmedTricks,
  }) {
    for (final playerId in scoringOrder) {
      if (!confirmedTricks.containsKey(playerId)) {
        return playerId;
      }
    }
    return null;
  }

  ScoringLoaded _buildLoadedState({
    required Game game,
    required Round round,
    required List<String> scoringOrder,
    required Map<String, int> confirmedTricks,
    required String? currentPlayerId,
    required int draftTrick,
    String? editingPlayerId,
  }) {
    final effectiveTricks = Map<String, int>.from(confirmedTricks);
    if (editingPlayerId != null) {
      effectiveTricks[editingPlayerId] = draftTrick;
    }

    final tricksSum = _validator.partialTricksSum(effectiveTricks);
    final remainingTricks = round.cardsInRound - tricksSum;

    final tricksForLimit = Map<String, int>.from(confirmedTricks);
    if (editingPlayerId != null) {
      tricksForLimit[editingPlayerId] = draftTrick;
    } else if (currentPlayerId != null) {
      tricksForLimit[currentPlayerId] = draftTrick;
    }
    final totalTricks = _validator.partialTricksSum(tricksForLimit);
    final canAddMore = totalTricks < round.cardsInRound;

    final isDraftInRange = _validator.isTrickInRange(
      trick: draftTrick,
      cardsInRound: round.cardsInRound,
    );

    final canConfirmTrick = editingPlayerId != null
        ? isDraftInRange
        : currentPlayerId != null && isDraftInRange;

    final canConfirm = editingPlayerId != null
        ? false
        : _validator.canClose(
            cardsInRound: round.cardsInRound,
            tricks: confirmedTricks,
            playerIds: scoringOrder,
          );

    return ScoringLoaded(
      game: game,
      round: round,
      scoringOrder: scoringOrder,
      confirmedTricks: confirmedTricks,
      currentPlayerId: currentPlayerId,
      draftTrick: draftTrick,
      tricksSum: tricksSum,
      remainingTricks: remainingTricks,
      canConfirmTrick: canConfirmTrick,
      canConfirm: canConfirm,
      canAddMore: canAddMore,
      editingPlayerId: editingPlayerId,
    );
  }
}
