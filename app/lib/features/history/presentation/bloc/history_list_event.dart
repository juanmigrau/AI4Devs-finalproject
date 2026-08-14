part of 'history_list_bloc.dart';

sealed class HistoryListEvent extends Equatable {
  const HistoryListEvent();

  @override
  List<Object?> get props => [];
}

class HistoryListStarted extends HistoryListEvent {
  const HistoryListStarted();
}

class HistoryListRefreshed extends HistoryListEvent {
  const HistoryListRefreshed();
}

class HistoryListGameDeleted extends HistoryListEvent {
  const HistoryListGameDeleted(this.gameId);

  final String gameId;

  @override
  List<Object?> get props => [gameId];
}

class _HistoryListWatchData extends HistoryListEvent {
  const _HistoryListWatchData(this.result);

  final GameHistoryLoadResult result;

  @override
  List<Object?> get props => [result];
}

class _HistoryListWatchFailed extends HistoryListEvent {
  const _HistoryListWatchFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
