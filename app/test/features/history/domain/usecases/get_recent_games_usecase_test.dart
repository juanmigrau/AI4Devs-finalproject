import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/repositories/history_repository.dart';
import 'package:la_pocha/features/history/domain/usecases/get_recent_games_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_recent_games_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<HistoryRepository>()])
void main() {
  late MockHistoryRepository repository;
  late GetRecentGamesUseCase useCase;

  final items = [
    GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 8, 12, 21, 30),
      playerCount: 4,
      displayLabel: '12 ago 2026, 21:30 — Ana, Luis',
      winnerName: 'Ana',
      winnerScore: 40,
    ),
  ];

  setUp(() {
    repository = MockHistoryRepository();
    useCase = GetRecentGamesUseCase(repository);
  });

  test('returns recent finished games with default limit of 3', () async {
    when(
      repository.getRecentFinishedGames(limit: 3),
    ).thenAnswer((_) async => items);

    final result = await useCase();

    expect(result, items);
    verify(repository.getRecentFinishedGames(limit: 3)).called(1);
  });

  test('forwards a custom limit to the repository', () async {
    when(
      repository.getRecentFinishedGames(limit: 1),
    ).thenAnswer((_) async => items);

    final result = await useCase(limit: 1);

    expect(result, items);
    verify(repository.getRecentFinishedGames(limit: 1)).called(1);
  });
}
