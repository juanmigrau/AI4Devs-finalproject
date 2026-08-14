import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_load_result.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_history_usecase.dart';
import 'package:la_pocha/features/sync/domain/usecases/retry_pending_uploads_usecase.dart';

part 'history_list_event.dart';
part 'history_list_state.dart';

class HistoryListBloc extends Bloc<HistoryListEvent, HistoryListState> {
  HistoryListBloc({
    required this._getGameHistory,
    required this._retryPendingUploads,
  }) : super(const HistoryListInitial()) {
    on<HistoryListStarted>(_onStarted);
    on<HistoryListRefreshed>(_onRefreshed);
    on<HistoryListGameDeleted>(_onGameDeleted);
    on<_HistoryListWatchData>(_onWatchData);
    on<_HistoryListWatchFailed>(_onWatchFailed);
  }

  final GetGameHistoryUseCase _getGameHistory;
  final RetryPendingUploadsUseCase _retryPendingUploads;
  StreamSubscription<GameHistoryLoadResult>? _subscription;

  Future<void> _onStarted(
    HistoryListStarted event,
    Emitter<HistoryListState> emit,
  ) async {
    emit(const HistoryListLoading());
    try {
      await _retryPendingUploads();
      await _listenToWatch();
    } catch (error) {
      emit(HistoryListFailure(message: mapExceptionToUserMessage(error)));
    }
  }

  Future<void> _onRefreshed(
    HistoryListRefreshed event,
    Emitter<HistoryListState> emit,
  ) async {
    // Retry pending uploads when auth and upload are available.
    try {
      await _retryPendingUploads();
      final result = await _getGameHistory();
      _emitHistoryResult(result, emit);
    } catch (error) {
      emit(HistoryListFailure(message: mapExceptionToUserMessage(error)));
    }
  }

  void _onGameDeleted(
    HistoryListGameDeleted event,
    Emitter<HistoryListState> emit,
  ) {
    final current = state;
    if (current is! HistoryListLoaded) {
      return;
    }

    final updatedItems = current.items
        .where(
          (item) =>
              item.id != event.gameId && item.cloudGameId != event.gameId,
        )
        .toList();

    if (updatedItems.isEmpty) {
      emit(const HistoryListEmpty());
      return;
    }

    emit(
      HistoryListLoaded(
        items: updatedItems,
        cloudError: current.cloudError,
      ),
    );
  }

  void _onWatchData(
    _HistoryListWatchData event,
    Emitter<HistoryListState> emit,
  ) {
    _emitHistoryResult(event.result, emit);
  }

  void _onWatchFailed(
    _HistoryListWatchFailed event,
    Emitter<HistoryListState> emit,
  ) {
    emit(HistoryListFailure(message: mapExceptionToUserMessage(event.error)));
  }

  Future<void> _listenToWatch() async {
    await _subscription?.cancel();
    _subscription = _getGameHistory.watch().listen(
      (result) => add(_HistoryListWatchData(result)),
      onError: (Object error, StackTrace _) =>
          add(_HistoryListWatchFailed(error)),
    );
  }

  void _emitHistoryResult(
    GameHistoryLoadResult result,
    Emitter<HistoryListState> emit,
  ) {
    if (result.items.isEmpty) {
      emit(const HistoryListEmpty());
      return;
    }
    emit(
      HistoryListLoaded(
        items: result.items,
        cloudError: result.cloudError,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
