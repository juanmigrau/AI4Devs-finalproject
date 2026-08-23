import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/round/domain/entities/game_curiosities.dart';
import 'package:la_pocha/features/round/domain/entities/game_stats.dart';
import 'package:la_pocha/features/round/domain/usecases/get_game_stats_usecase.dart';
import 'package:mockito/mockito.dart';

import 'get_game_scorecard_usecase_test.mocks.dart';

void main() {
  late MockGameRepository gameRepository;
  late MockRoundRepository roundRepository;
  late GetGameStatsUseCase useCase;

  final players = [
    PlayerEmbed(
      id: 'p0',
      displayName: 'Bob',
      isGuest: true,
      userId: null,
      seatOrder: 0,
      totalScore: 30,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 5,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p2',
      displayName: 'Carla',
      isGuest: true,
      userId: null,
      seatOrder: 2,
      totalScore: -5,
      joinedAt: DateTime(2026),
    ),
  ];

  final game = Game(
    id: 'game-1',
    status: GameStatus.inProgress,
    playerCount: 3,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [
      RoundDefinition(roundNumber: 1, cardsPerPlayer: 1),
      RoundDefinition(roundNumber: 2, cardsPerPlayer: 2),
      RoundDefinition(roundNumber: 3, cardsPerPlayer: 3),
    ],
    players: players,
    currentRoundNumber: 3,
    startedAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Round closedRound({
    required int number,
    required int cards,
    required Map<String, int> bids,
    required Map<String, int> tricks,
    required Map<String, int> scoresDelta,
  }) {
    return Round(
      id: 'round-$number',
      gameId: 'game-1',
      roundNumber: number,
      cardsInRound: cards,
      dealerPlayerId: 'p0',
      status: RoundStatus.closed,
      bids: bids,
      tricks: tricks,
      scoresDelta: scoresDelta,
      createdAt: DateTime(2026),
      closedAt: DateTime(2026),
    );
  }

  /// Three closed rounds designed for clear expectations:
  ///
  /// Round 1 (1 card): p0 hit, p1 miss, p2 hit
  /// Round 2 (2 cards): p0 hit, p1 hit, p2 miss
  /// Round 3 (3 cards): p0 miss, p1 hit, p2 miss
  ///
  /// Accuracy: p1=2/3, p0=2/3, p2=1/3
  /// Current streak (from end): p0=0, p1=2, p2=0
  /// Best streak: p0=2, p1=2, p2=1
  /// Bid ratios: p0=4/6, p1=2/6, p2=1/6 → riskiest p0, conservative p2
  /// Most equal round: round 2 (spread 2) vs r1/r3 (21)
  List<Round> threeClosedRounds() => [
        closedRound(
          number: 1,
          cards: 1,
          bids: const {'p0': 1, 'p1': 0, 'p2': 0},
          tricks: const {'p0': 1, 'p1': 1, 'p2': 0},
          scoresDelta: const {'p0': 11, 'p1': -10, 'p2': 10},
        ),
        closedRound(
          number: 2,
          cards: 2,
          bids: const {'p0': 2, 'p1': 1, 'p2': 0},
          tricks: const {'p0': 2, 'p1': 1, 'p2': 1},
          scoresDelta: const {'p0': 12, 'p1': 11, 'p2': 10},
        ),
        closedRound(
          number: 3,
          cards: 3,
          bids: const {'p0': 1, 'p1': 1, 'p2': 1},
          tricks: const {'p0': 0, 'p1': 1, 'p2': 0},
          scoresDelta: const {'p0': -10, 'p1': 11, 'p2': -10},
        ),
      ];

  setUp(() {
    gameRepository = MockGameRepository();
    roundRepository = MockRoundRepository();
    useCase = GetGameStatsUseCase(gameRepository, roundRepository);
  });

  test('computes accuracy, streaks and averages for each player', () async {
    when(gameRepository.getGameById('game-1')).thenAnswer((_) async => game);
    when(roundRepository.getRoundsByGameId('game-1'))
        .thenAnswer((_) async => threeClosedRounds());

    final stats = await useCase(gameId: 'game-1');

    expect(stats.closedRoundCount, 3);
    expect(stats.players.map((p) => p.id), ['p0', 'p1', 'p2']);

    // Sorted by accuracy descending; ties keep relative order from seatOrder sort
    // of input when accuracies equal — p0 and p1 both 2/3.
    final byId = {
      for (final s in stats.playerStats) s.playerId: s,
    };

    expect(byId['p0']!.accuracyPercent, closeTo(66.666, 0.01));
    expect(byId['p0']!.currentStreak, 0);
    expect(byId['p0']!.bestStreak, 2);
    expect(byId['p0']!.totalBids, 4);
    expect(byId['p0']!.totalTricks, 3);
    expect(byId['p0']!.bestRoundDelta, 12);
    expect(byId['p0']!.worstRoundDelta, -10);
    expect(byId['p0']!.averageScorePerRound, closeTo(13 / 3, 0.01));

    expect(byId['p1']!.accuracyPercent, closeTo(66.666, 0.01));
    expect(byId['p1']!.currentStreak, 2);
    expect(byId['p1']!.bestStreak, 2);
    expect(byId['p1']!.totalBids, 2);
    expect(byId['p1']!.totalTricks, 3);

    expect(byId['p2']!.accuracyPercent, closeTo(33.333, 0.01));
    expect(byId['p2']!.currentStreak, 0);
    expect(byId['p2']!.bestStreak, 1);

    expect(stats.playerStats.first.accuracyPercent! >=
        stats.playerStats.last.accuracyPercent!, isTrue);
    expect(stats.playerStats.last.playerId, 'p2');
  });

  test('computes curiosities from at least three closed rounds', () async {
    when(gameRepository.getGameById('game-1')).thenAnswer((_) async => game);
    when(roundRepository.getRoundsByGameId('game-1'))
        .thenAnswer((_) async => threeClosedRounds());

    final stats = await useCase(gameId: 'game-1');

    expect(stats.curiosities.mostEqualRoundNumber, 2);
    expect(stats.curiosities.riskiestPlayerId, 'p0');
    expect(stats.curiosities.riskiestPlayerName, 'Bob');
    expect(stats.curiosities.mostConservativePlayerId, 'p2');
    expect(stats.curiosities.mostConservativePlayerName, 'Carla');
  });

  test('builds cumulative progress series with positions', () async {
    when(gameRepository.getGameById('game-1')).thenAnswer((_) async => game);
    when(roundRepository.getRoundsByGameId('game-1'))
        .thenAnswer((_) async => threeClosedRounds());

    final stats = await useCase(gameId: 'game-1');

    expect(stats.progressSeries, hasLength(3));
    final seriesById = {
      for (final s in stats.progressSeries) s.playerId: s,
    };

    // After R1: p0=11(1st), p2=10(2nd), p1=-10(3rd)
    expect(seriesById['p0']!.points[0],
        const PlayerProgressPoint(roundNumber: 1, cumulativeScore: 11, position: 1));
    expect(seriesById['p2']!.points[0],
        const PlayerProgressPoint(roundNumber: 1, cumulativeScore: 10, position: 2));
    expect(seriesById['p1']!.points[0],
        const PlayerProgressPoint(roundNumber: 1, cumulativeScore: -10, position: 3));

    // After R2: p0=23, p2=20, p1=1
    expect(seriesById['p0']!.points[1].cumulativeScore, 23);
    expect(seriesById['p0']!.points[1].position, 1);
    expect(seriesById['p2']!.points[1].cumulativeScore, 20);
    expect(seriesById['p2']!.points[1].position, 2);
    expect(seriesById['p1']!.points[1].cumulativeScore, 1);
    expect(seriesById['p1']!.points[1].position, 3);

    // After R3: p0=13, p1=12, p2=10
    expect(seriesById['p0']!.points[2].cumulativeScore, 13);
    expect(seriesById['p0']!.points[2].position, 1);
    expect(seriesById['p1']!.points[2].cumulativeScore, 12);
    expect(seriesById['p1']!.points[2].position, 2);
    expect(seriesById['p2']!.points[2].cumulativeScore, 10);
    expect(seriesById['p2']!.points[2].position, 3);
  });

  test('returns empty-friendly stats when there are no closed rounds', () async {
    when(gameRepository.getGameById('game-1')).thenAnswer((_) async => game);
    when(roundRepository.getRoundsByGameId('game-1')).thenAnswer(
      (_) async => [
        Round(
          id: 'round-1',
          gameId: 'game-1',
          roundNumber: 1,
          cardsInRound: 1,
          dealerPlayerId: 'p0',
          status: RoundStatus.bidding,
          bids: const {},
          createdAt: DateTime(2026),
        ),
      ],
    );

    final stats = await useCase(gameId: 'game-1');

    expect(stats.closedRoundCount, 0);
    expect(stats.progressSeries.every((s) => s.points.isEmpty), isTrue);
    expect(
      stats.playerStats.every((s) => s.accuracyPercent == null),
      isTrue,
    );
    expect(stats.curiosities, const GameCuriosities.empty());
  });

  test('throws when game is not found', () async {
    when(gameRepository.getGameById('missing')).thenAnswer((_) async => null);

    expect(
      () => useCase(gameId: 'missing'),
      throwsA(isA<StateError>()),
    );
  });
}
