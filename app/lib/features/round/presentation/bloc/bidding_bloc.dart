import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/round/domain/services/dealer_restriction_validator.dart';
import 'package:la_pocha/features/round/domain/usecases/close_bidding_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/load_bidding_context_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/submit_bid_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/update_bid_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/bidding_event.dart';
import 'package:la_pocha/features/round/presentation/bloc/bidding_state.dart';

class BiddingBloc extends Bloc<BiddingEvent, BiddingState> {
  BiddingBloc({
    required this._loadBiddingContext,
    required this._submitBid,
    required this._updateBid,
    required this._closeBidding,
    DealerRestrictionValidator? validator,
  }) : _validator = validator ?? const DealerRestrictionValidator(),
       super(const BiddingInitial()) {
    on<BiddingStarted>(_onBiddingStarted);
    on<BidValueChanged>(_onBidValueChanged);
    on<BidConfirmed>(_onBidConfirmed);
    on<BidEditActivated>(_onBidEditActivated);
    on<BidEditCancelled>(_onBidEditCancelled);
    on<BidUpdated>(_onBidUpdated);
    on<CloseBiddingRequested>(_onCloseBiddingRequested);
  }

  final LoadBiddingContextUseCase _loadBiddingContext;
  final SubmitBidUseCase _submitBid;
  final UpdateBidUseCase _updateBid;
  final CloseBiddingUseCase _closeBidding;
  final DealerRestrictionValidator _validator;

  Future<void> _onBiddingStarted(
    BiddingStarted event,
    Emitter<BiddingState> emit,
  ) async {
    emit(const BiddingLoading());
    try {
      final context = await _loadBiddingContext(
        gameId: event.gameId,
        roundNumber: event.roundNumber,
      );
      emit(
        _buildLoadedState(
          game: context.game,
          round: context.round,
          biddingOrder: context.biddingOrder,
          currentPlayerId: context.currentPlayerId,
          draftBid: 0,
        ),
      );
    } catch (error) {
      emit(BiddingFailure(message: mapExceptionToUserMessage(error)));
    }
  }

  void _onBidValueChanged(BidValueChanged event, Emitter<BiddingState> emit) {
    final current = state;
    if (current is! BiddingLoaded) {
      return;
    }
    if (current.editingPlayerId == null && current.currentPlayerId == null) {
      return;
    }

    emit(
      _buildLoadedState(
        game: current.game,
        round: current.round,
        biddingOrder: current.biddingOrder,
        currentPlayerId: current.currentPlayerId,
        draftBid: event.bid,
        editingPlayerId: current.editingPlayerId,
      ),
    );
  }

  Future<void> _onBidConfirmed(
    BidConfirmed event,
    Emitter<BiddingState> emit,
  ) async {
    final current = state;
    if (current is! BiddingLoaded ||
        current.editingPlayerId != null ||
        current.currentPlayerId == null ||
        !current.canConfirmBid ||
        current.isSubmitting) {
      return;
    }

    emit(current.copyWith(isSubmitting: true, validationMessage: () => null));
    try {
      final result = await _submitBid(
        round: current.round,
        biddingOrder: current.biddingOrder,
        currentPlayerId: current.currentPlayerId!,
        bid: current.draftBid,
      );

      emit(
        _buildLoadedState(
          game: current.game,
          round: result.round,
          biddingOrder: result.biddingOrder,
          currentPlayerId: result.currentPlayerId,
          draftBid: 0,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isSubmitting: false,
          validationMessage: () => mapExceptionToUserMessage(error),
        ),
      );
    }
  }

  void _onBidEditActivated(
    BidEditActivated event,
    Emitter<BiddingState> emit,
  ) {
    final current = state;
    if (current is! BiddingLoaded) {
      return;
    }
    if (!current.round.bids.containsKey(event.playerId)) {
      return;
    }

    emit(
      _buildLoadedState(
        game: current.game,
        round: current.round,
        biddingOrder: current.biddingOrder,
        currentPlayerId: current.currentPlayerId,
        draftBid: current.round.bids[event.playerId]!,
        editingPlayerId: event.playerId,
      ),
    );
  }

  void _onBidEditCancelled(
    BidEditCancelled event,
    Emitter<BiddingState> emit,
  ) {
    final current = state;
    if (current is! BiddingLoaded || current.editingPlayerId == null) {
      return;
    }

    emit(
      _buildLoadedState(
        game: current.game,
        round: current.round,
        biddingOrder: current.biddingOrder,
        currentPlayerId: current.currentPlayerId,
        draftBid: 0,
      ),
    );
  }

  Future<void> _onBidUpdated(
    BidUpdated event,
    Emitter<BiddingState> emit,
  ) async {
    final current = state;
    if (current is! BiddingLoaded ||
        current.editingPlayerId != event.playerId ||
        !current.canConfirmBid ||
        current.isSubmitting) {
      return;
    }

    emit(current.copyWith(isSubmitting: true, validationMessage: () => null));
    try {
      final updatedRound = await _updateBid(
        round: current.round,
        playerId: event.playerId,
        newBid: event.newBid,
      );

      emit(
        _buildLoadedState(
          game: current.game,
          round: updatedRound,
          biddingOrder: current.biddingOrder,
          currentPlayerId: current.currentPlayerId,
          draftBid: 0,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isSubmitting: false,
          validationMessage: () => mapExceptionToUserMessage(error),
        ),
      );
    }
  }

  Future<void> _onCloseBiddingRequested(
    CloseBiddingRequested event,
    Emitter<BiddingState> emit,
  ) async {
    final current = state;
    if (current is! BiddingLoaded || !current.canClose || current.isClosing) {
      return;
    }

    emit(current.copyWith(isClosing: true));
    try {
      await _closeBidding(
        round: current.round,
        playerIds: current.biddingOrder,
      );
      emit(
        BiddingNavigateToPlay(
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

  BiddingLoaded _buildLoadedState({
    required Game game,
    required Round round,
    required List<String> biddingOrder,
    required String? currentPlayerId,
    required int draftBid,
    String? editingPlayerId,
  }) {
    final effectiveBids = Map<String, int>.from(round.bids);
    if (editingPlayerId != null) {
      effectiveBids[editingPlayerId] = draftBid;
    }

    final partialSum = _validator.partialBidSum(effectiveBids);
    final availableTricks = _validator.availableTricks(
      cardsInRound: round.cardsInRound,
      bids: effectiveBids,
    );

    final dealerHasBid = round.bids.containsKey(round.dealerPlayerId);
    final isDealerTurn = currentPlayerId == round.dealerPlayerId;
    final shouldExposeForbidden = isDealerTurn || dealerHasBid;

    final bidsBeforeDealer = Map<String, int>.from(effectiveBids)
      ..remove(round.dealerPlayerId);
    final forbiddenBid = shouldExposeForbidden
        ? _validator.forbiddenBidForDealer(
            cardsInRound: round.cardsInRound,
            bidsBeforeDealer: bidsBeforeDealer,
          )
        : null;

    final isDraftInRange = draftBid >= 0 && draftBid <= round.cardsInRound;
    final isEditingDealer = editingPlayerId == round.dealerPlayerId;
    final isActiveDealerTurn =
        editingPlayerId == null && currentPlayerId == round.dealerPlayerId;
    final appliesDealerRestriction = isEditingDealer || isActiveDealerTurn;
    final isForbidden =
        appliesDealerRestriction &&
        forbiddenBid != null &&
        _validator.isForbiddenBid(bid: draftBid, forbiddenBid: forbiddenBid);

    final canConfirmBid = editingPlayerId != null
        ? isDraftInRange && !isForbidden
        : currentPlayerId != null && isDraftInRange && !isForbidden;

    // canClose uses persisted bids only (not the edit draft).
    final canClose = editingPlayerId != null
        ? false
        : _validator.canClose(
            cardsInRound: round.cardsInRound,
            bids: round.bids,
            playerIds: biddingOrder,
          );

    return BiddingLoaded(
      game: game,
      round: round,
      biddingOrder: biddingOrder,
      currentPlayerId: currentPlayerId,
      draftBid: draftBid,
      partialSum: partialSum,
      availableTricks: availableTricks,
      forbiddenBid: forbiddenBid,
      canConfirmBid: canConfirmBid,
      canClose: canClose,
      editingPlayerId: editingPlayerId,
    );
  }
}
