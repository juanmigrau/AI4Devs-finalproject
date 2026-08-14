import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_load_result.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_history_usecase.dart';
import 'package:la_pocha/features/history/presentation/bloc/history_list_bloc.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';
import 'package:la_pocha/features/sync/domain/usecases/retry_pending_uploads_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'history_list_bloc_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetGameHistoryUseCase>(),
  MockSpec<RetryPendingUploadsUseCase>(),
])
void main() {
  late MockGetGameHistoryUseCase getGameHistory;
  late MockRetryPendingUploadsUseCase retryPendingUploads;

  final items = [
    GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
    ),
  ];

  final pendingItems = [
    GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
      syncStatus: SyncStatus.pending,
    ),
    GameHistoryItem(
      id: 'game-2',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 5),
      playerCount: 3,
      displayLabel: '5 jul 2026 — Luis',
      winnerName: 'Luis',
      winnerScore: 10,
      syncStatus: SyncStatus.failed,
    ),
  ];

  setUp(() {
    getGameHistory = MockGetGameHistoryUseCase();
    retryPendingUploads = MockRetryPendingUploadsUseCase();
    when(retryPendingUploads()).thenAnswer((_) async => 0);
  });

  HistoryListBloc buildBloc() => HistoryListBloc(
        getGameHistory: getGameHistory,
        retryPendingUploads: retryPendingUploads,
      );

  blocTest<HistoryListBloc, HistoryListState>(
    'emits loaded when history has items',
    build: buildBloc,
    setUp: () {
      when(getGameHistory.watch()).thenAnswer(
        (_) => Stream.value(GameHistoryLoadResult(items: items)),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const HistoryListLoading(),
      HistoryListLoaded(items: items),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'emits loaded with cloudError when cloud load failed',
    build: buildBloc,
    setUp: () {
      when(getGameHistory.watch()).thenAnswer(
        (_) => Stream.value(
          GameHistoryLoadResult(items: items, cloudError: true),
        ),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const HistoryListLoading(),
      HistoryListLoaded(items: items, cloudError: true),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'emits empty when history has no items',
    build: buildBloc,
    setUp: () {
      when(getGameHistory.watch()).thenAnswer(
        (_) => Stream.value(const GameHistoryLoadResult(items: [])),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const HistoryListLoading(),
      const HistoryListEmpty(),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'reloads items on refresh without loading state',
    build: buildBloc,
    setUp: () {
      when(getGameHistory()).thenAnswer(
        (_) async => GameHistoryLoadResult(items: items),
      );
    },
    seed: () => HistoryListLoaded(items: items),
    act: (bloc) => bloc.add(const HistoryListRefreshed()),
    expect: () => [],
    verify: (_) {
      verify(getGameHistory()).called(1);
    },
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'emits failure without DEBUG details when watch stream errors',
    build: buildBloc,
    setUp: () {
      when(getGameHistory.watch()).thenAnswer(
        (_) => Stream.error(Exception('network error')),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const HistoryListLoading(),
      isA<HistoryListFailure>().having(
        (state) => state.message,
        'message',
        isNot(contains('[DEBUG]')),
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'updates list when watch emits again after a deletion',
    build: buildBloc,
    setUp: () {
      when(getGameHistory.watch()).thenAnswer(
        (_) => Stream.fromIterable([
          GameHistoryLoadResult(items: items),
          const GameHistoryLoadResult(items: []),
        ]),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const HistoryListLoading(),
      HistoryListLoaded(items: items),
      const HistoryListEmpty(),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'removes deleted game optimistically from loaded list',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: items),
    act: (bloc) => bloc.add(const HistoryListGameDeleted('game-1')),
    expect: () => [const HistoryListEmpty()],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'preserves cloudError when deleting one of several items',
    build: buildBloc,
    seed: () => HistoryListLoaded(
      items: [
        items.first,
        GameHistoryItem(
          id: 'game-2',
          source: GameHistorySource.local,
          finishedAt: DateTime(2026, 7, 5),
          playerCount: 3,
          displayLabel: '5 jul 2026 — Luis',
          winnerName: 'Luis',
          winnerScore: 10,
        ),
      ],
      cloudError: true,
    ),
    act: (bloc) => bloc.add(const HistoryListGameDeleted('game-1')),
    expect: () => [
      HistoryListLoaded(
        items: [
          GameHistoryItem(
            id: 'game-2',
            source: GameHistorySource.local,
            finishedAt: DateTime(2026, 7, 5),
            playerCount: 3,
            displayLabel: '5 jul 2026 — Luis',
            winnerName: 'Luis',
            winnerScore: 10,
          ),
        ],
        cloudError: true,
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'SyncRetryRequested shows syncing then success feedback',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: pendingItems),
    setUp: () {
      when(retryPendingUploads(gameId: 'game-1'))
          .thenAnswer((_) async => 1);
    },
    act: (bloc) =>
        bloc.add(const SyncRetryRequested(gameId: 'game-1')),
    expect: () => [
      HistoryListLoaded(
        items: pendingItems,
        syncingGameIds: const {'game-1'},
      ),
      HistoryListLoaded(
        items: pendingItems,
        syncRetryFeedback: HistorySyncRetryFeedback.success,
      ),
    ],
    verify: (_) {
      verify(retryPendingUploads(gameId: 'game-1')).called(1);
    },
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'SyncRetryRequested shows failure feedback when upload does not sync',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: pendingItems),
    setUp: () {
      when(retryPendingUploads(gameId: 'game-1'))
          .thenAnswer((_) async => 0);
    },
    act: (bloc) =>
        bloc.add(const SyncRetryRequested(gameId: 'game-1')),
    expect: () => [
      HistoryListLoaded(
        items: pendingItems,
        syncingGameIds: const {'game-1'},
      ),
      HistoryListLoaded(
        items: pendingItems,
        syncRetryFeedback: HistorySyncRetryFeedback.failure,
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'SyncAllPendingRequested retries all pending and failed games',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: pendingItems),
    setUp: () {
      when(retryPendingUploads()).thenAnswer((_) async => 2);
    },
    act: (bloc) => bloc.add(const SyncAllPendingRequested()),
    expect: () => [
      HistoryListLoaded(
        items: pendingItems,
        syncingGameIds: const {'game-1', 'game-2'},
      ),
      HistoryListLoaded(
        items: pendingItems,
        syncRetryFeedback: HistorySyncRetryFeedback.success,
      ),
    ],
    verify: (_) {
      verify(retryPendingUploads()).called(1);
    },
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'SyncAllPendingRequested emits failure when not all games sync',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: pendingItems),
    setUp: () {
      when(retryPendingUploads()).thenAnswer((_) async => 1);
    },
    act: (bloc) => bloc.add(const SyncAllPendingRequested()),
    expect: () => [
      HistoryListLoaded(
        items: pendingItems,
        syncingGameIds: const {'game-1', 'game-2'},
      ),
      HistoryListLoaded(
        items: pendingItems,
        syncRetryFeedback: HistorySyncRetryFeedback.failure,
      ),
    ],
  );
}
