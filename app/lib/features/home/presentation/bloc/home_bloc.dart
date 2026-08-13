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
  }

  final GetRecentGamesUseCase _getRecentGames;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());

    try {
      final recentGames = await _getRecentGames();
      if (recentGames.isEmpty) {
        emit(const HomeEmpty());
        return;
      }
      emit(HomeLoaded(recentGames: recentGames));
    } catch (error) {
      emit(HomeFailure(message: mapExceptionToUserMessage(error)));
    }
  }
}
