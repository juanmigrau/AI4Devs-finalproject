part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class _HomeWatchData extends HomeEvent {
  const _HomeWatchData(this.recentGames);

  final List<GameHistoryItem> recentGames;

  @override
  List<Object?> get props => [recentGames];
}

class _HomeWatchFailed extends HomeEvent {
  const _HomeWatchFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
