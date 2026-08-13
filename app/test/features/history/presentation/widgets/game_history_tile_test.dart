import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/presentation/widgets/game_history_tile.dart';

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

  testWidgets('renders local badge, display label and winner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: GameHistoryTile(item: item, onTap: () {}),
        ),
      ),
    );

    expect(find.text('4 jul 2026, 22:00'), findsOneWidget);
    expect(find.text('Ana, Carlos'), findsOneWidget);
    expect(find.text('4 jugadores · Ganador: Ana (42 pts)'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.byIcon(Icons.phone_android), findsOneWidget);
  });

  testWidgets('does not show overflow menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: GameHistoryTile(item: item, onTap: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Ver detalle'), findsNothing);
    expect(find.text('Repetir partida'), findsNothing);
  });

  testWidgets('calls onTap when tapping any part of the tile', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: GameHistoryTile(item: item, onTap: () => tapCount++),
        ),
      ),
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

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: GameHistoryTile(item: longNamesItem, onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.text(playerNames), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
