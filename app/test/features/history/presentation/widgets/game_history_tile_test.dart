import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/presentation/bloc/history_list_bloc.dart';
import 'package:la_pocha/features/history/presentation/widgets/game_history_tile.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryListBloc extends MockBloc<HistoryListEvent, HistoryListState>
    implements HistoryListBloc {}

void main() {
  final item = GameHistoryItem(
    id: 'game-1',
    source: GameHistorySource.local,
    finishedAt: DateTime(2026, 7, 4, 22, 0),
    playerCount: 4,
    displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
    winnerName: 'Ana',
    winnerScore: 42,
  );

  Widget wrapTile({
    required GameHistoryItem tileItem,
    required VoidCallback onTap,
    HistoryListBloc? bloc,
    HistoryListState? state,
  }) {
    final historyBloc = bloc ?? MockHistoryListBloc();
    final loadedState = state ?? HistoryListLoaded(items: [tileItem]);
    whenListen(
      historyBloc,
      Stream.value(loadedState),
      initialState: loadedState,
    );

    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<HistoryListBloc>.value(
          value: historyBloc,
          child: GameHistoryTile(item: tileItem, onTap: onTap),
        ),
      ),
    );
  }

  testWidgets('renders local badge, display label and winner', (tester) async {
    await tester.pumpWidget(wrapTile(tileItem: item, onTap: () {}));

    expect(find.text('4 jul 2026, 22:00'), findsOneWidget);
    expect(find.text('Ana, Carlos'), findsOneWidget);
    expect(find.text('4 jugadores · Ganador: Ana (42 pts)'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.byIcon(Icons.phone_android), findsOneWidget);
  });

  testWidgets('does not show overflow menu', (tester) async {
    await tester.pumpWidget(wrapTile(tileItem: item, onTap: () {}));

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Ver detalle'), findsNothing);
    expect(find.text('Repetir partida'), findsNothing);
  });

  testWidgets('calls onTap when tapping any part of the tile', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      wrapTile(tileItem: item, onTap: () => tapCount++),
    );

    await tester.tap(find.text('4 jul 2026, 22:00'));
    await tester.pump();
    expect(tapCount, 1);

    await tester.tap(find.text('Ana, Carlos'));
    await tester.pump();
    expect(tapCount, 2);

    await tester.tap(find.text('Local'));
    await tester.pump();
    expect(tapCount, 3);

    await tester.tap(find.text('4 jugadores · Ganador: Ana (42 pts)'));
    await tester.pump();
    expect(tapCount, 4);
  });

  testWidgets('wraps long player names without overflow', (tester) async {
    const playerNames =
        'AlejandroMaximiliano, BartolomeConstancio, '
        'CristobalHernandez, DomingaValentina, '
        'EsperanzaSoledad, FranciscoJavierLuis, '
        'GuadalupeAntonia, HerminiaDoloresPaz';
    final longNamesItem = GameHistoryItem(
      id: 'game-2',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4, 22, 0),
      playerCount: 8,
      displayLabel: '4 jul 2026, 22:00 — $playerNames',
      winnerName: 'AlejandroMaximiliano',
      winnerScore: 42,
    );

    final historyBloc = MockHistoryListBloc();
    final loadedState = HistoryListLoaded(items: [longNamesItem]);
    whenListen(
      historyBloc,
      Stream.value(loadedState),
      initialState: loadedState,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: BlocProvider<HistoryListBloc>.value(
              value: historyBloc,
              child: GameHistoryTile(item: longNamesItem, onTap: () {}),
            ),
          ),
        ),
      ),
    );

    expect(find.text(playerNames), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows pending sync chip and refresh button', (tester) async {
    final pendingItem = GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4, 22, 0),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
      syncStatus: SyncStatus.pending,
    );

    await tester.pumpWidget(wrapTile(tileItem: pendingItem, onTap: () {}));

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Local'), findsNothing);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(find.byIcon(Icons.refresh_outlined), findsOneWidget);
  });

  testWidgets('shows failed sync chip and refresh button', (tester) async {
    final failedItem = GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4, 22, 0),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
      syncStatus: SyncStatus.failed,
    );

    await tester.pumpWidget(wrapTile(tileItem: failedItem, onTap: () {}));

    expect(find.text('Error sync'), findsOneWidget);
    expect(find.text('Local'), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.refresh_outlined), findsOneWidget);
  });

  testWidgets('shows Nube chip without refresh for cloud source', (
    tester,
  ) async {
    final cloudItem = GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.cloud,
      finishedAt: DateTime(2026, 7, 4, 22, 0),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
      syncStatus: SyncStatus.synced,
    );

    await tester.pumpWidget(wrapTile(tileItem: cloudItem, onTap: () {}));

    expect(find.text('Nube'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_outlined), findsNothing);
  });

  testWidgets('shows spinner while syncing', (tester) async {
    final pendingItem = GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4, 22, 0),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
      syncStatus: SyncStatus.pending,
    );

    await tester.pumpWidget(
      wrapTile(
        tileItem: pendingItem,
        onTap: () {},
        state: HistoryListLoaded(
          items: [pendingItem],
          syncingGameIds: const {'game-1'},
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.refresh_outlined), findsNothing);
  });

  testWidgets('dispatches SyncRetryRequested when refresh is tapped', (
    tester,
  ) async {
    final pendingItem = GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4, 22, 0),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
      syncStatus: SyncStatus.pending,
    );
    final bloc = MockHistoryListBloc();
    final loadedState = HistoryListLoaded(items: [pendingItem]);
    whenListen(
      bloc,
      Stream.value(loadedState),
      initialState: loadedState,
    );

    await tester.pumpWidget(
      wrapTile(tileItem: pendingItem, onTap: () {}, bloc: bloc),
    );

    await tester.tap(find.byIcon(Icons.refresh_outlined));
    await tester.pump();

    verify(
      () => bloc.add(const SyncRetryRequested(gameId: 'game-1')),
    ).called(1);
  });
}
