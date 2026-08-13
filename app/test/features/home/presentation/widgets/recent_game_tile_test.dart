import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/home/presentation/widgets/recent_game_tile.dart';

void main() {
  final item = GameHistoryItem(
    id: 'game-1',
    source: GameHistorySource.local,
    finishedAt: DateTime(2026, 8, 13, 20, 14),
    playerCount: 4,
    displayLabel: '13 ago 2026, 20:14 — Ana, Luis, Marta, Pedro',
    winnerName: 'Ana',
    winnerScore: 40,
  );

  final now = DateTime(2026, 8, 13, 22);

  testWidgets('renders relative date, player names and winner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RecentGameTile(item: item, now: now, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Hoy, 20:14'), findsOneWidget);
    expect(find.text('Ana, Luis, Marta, Pedro'), findsOneWidget);
    expect(find.text('Ganó Ana'), findsOneWidget);
    expect(find.textContaining('jugadores'), findsNothing);
  });

  testWidgets('calls onTap when the tile is pressed', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RecentGameTile(item: item, now: now, onTap: () => tapCount++),
        ),
      ),
    );

    await tester.tap(find.text('Ganó Ana'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('shows Sin ganador when winner is missing', (tester) async {
    final withoutWinner = GameHistoryItem(
      id: 'game-2',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 8, 12, 19, 2),
      playerCount: 3,
      displayLabel: '12 ago 2026, 19:02 — Ana, Luis, Marta',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RecentGameTile(item: withoutWinner, now: now, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Ayer, 19:02'), findsOneWidget);
    expect(find.text('Sin ganador'), findsOneWidget);
  });
}
