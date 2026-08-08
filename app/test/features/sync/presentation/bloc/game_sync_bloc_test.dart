import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/sync/domain/usecases/upload_finished_game_usecase.dart';
import 'package:la_pocha/features/sync/presentation/bloc/game_sync_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'game_sync_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<UploadFinishedGameUseCase>()])
void main() {
  late MockUploadFinishedGameUseCase uploadFinishedGame;

  setUp(() {
    uploadFinishedGame = MockUploadFinishedGameUseCase();
  });

  GameSyncBloc buildBloc() =>
      GameSyncBloc(uploadFinishedGame: uploadFinishedGame);

  blocTest<GameSyncBloc, GameSyncState>(
    'emits InProgress then Success when upload syncs',
    build: buildBloc,
    setUp: () {
      when(uploadFinishedGame(gameId: 'game-1')).thenAnswer(
        (_) async => UploadFinishedGameOutcome.synced,
      );
    },
    act: (bloc) => bloc.add(const GameUploadRequested(gameId: 'game-1')),
    expect: () => [
      isA<GameSyncInProgress>().having((s) => s.gameId, 'gameId', 'game-1'),
      isA<GameSyncSuccess>().having((s) => s.gameId, 'gameId', 'game-1'),
    ],
  );

  blocTest<GameSyncBloc, GameSyncState>(
    'emits InProgress then Failure when upload fails',
    build: buildBloc,
    setUp: () {
      when(uploadFinishedGame(gameId: 'game-1')).thenAnswer(
        (_) async => UploadFinishedGameOutcome.failed,
      );
    },
    act: (bloc) => bloc.add(const GameUploadRequested(gameId: 'game-1')),
    expect: () => [
      isA<GameSyncInProgress>().having((s) => s.gameId, 'gameId', 'game-1'),
      isA<GameSyncFailure>()
          .having((s) => s.gameId, 'gameId', 'game-1')
          .having(
            (s) => s.outcome,
            'outcome',
            UploadFinishedGameOutcome.failed,
          ),
    ],
  );

  blocTest<GameSyncBloc, GameSyncState>(
    'emits InProgress then Idle when upload is skipped',
    build: buildBloc,
    setUp: () {
      when(uploadFinishedGame(gameId: 'game-1')).thenAnswer(
        (_) async => UploadFinishedGameOutcome.skippedNoSession,
      );
    },
    act: (bloc) => bloc.add(const GameUploadRequested(gameId: 'game-1')),
    expect: () => [
      isA<GameSyncInProgress>().having((s) => s.gameId, 'gameId', 'game-1'),
      isA<GameSyncIdle>(),
    ],
  );
}
