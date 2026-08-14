import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/usecases/get_recent_games_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this._getRecentGames}) : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<_HomeWatchData>(_onWatchData);
    on<_HomeWatchFailed>(_onWatchFailed);
  }

  final GetRecentGamesUseCase _getRecentGames;
  StreamSubscription<List<GameHistoryItem>>? _subscription;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    await _subscription?.cancel();
    _subscription = _getRecentGames().listen(
      (games) => add(_HomeWatchData(games)),
      onError: (Object error, StackTrace _) => add(_HomeWatchFailed(error)),
    );
  }

  void _onWatchData(_HomeWatchData event, Emitter<HomeState> emit) {
    if (event.recentGames.isEmpty) {
      emit(const HomeEmpty());
      return;
    }
    emit(HomeLoaded(recentGames: event.recentGames));
  }

  void _onWatchFailed(_HomeWatchFailed event, Emitter<HomeState> emit) {
    emit(HomeFailure(message: mapExceptionToUserMessage(event.error)));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
