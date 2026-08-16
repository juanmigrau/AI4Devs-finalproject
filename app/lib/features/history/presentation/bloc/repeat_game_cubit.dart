import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/usecases/repeat_game_usecase.dart';

part 'repeat_game_state.dart';

const repeatGameFailureMessage =
    'No se pudo crear la partida. Inténtalo de nuevo.';

class RepeatGameCubit extends Cubit<RepeatGameState> {
  RepeatGameCubit({required this._repeatGame})
    : super(const RepeatGameInitial());

  final RepeatGameUseCase _repeatGame;

  Future<void> repeat({
    required String gameId,
    required GameHistorySource source,
  }) async {
    emit(const RepeatGameInProgress());
    try {
      final newGameId = await _repeatGame(
        sourceGameId: gameId,
        source: source,
      );
      emit(RepeatGameSuccess(newGameId: newGameId));
    } catch (_) {
      emit(const RepeatGameFailure(message: repeatGameFailureMessage));
    }
  }
}
