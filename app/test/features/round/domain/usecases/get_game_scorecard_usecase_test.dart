import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/round/domain/usecases/get_game_scorecard_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_game_scorecard_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GameRepository>(),
  MockSpec<RoundRepository>(),
])
void main() {
  late MockGameRepository gameRepository;
  late MockRoundRepository roundRepository;
  late GetGameScorecardUseCase useCase;

  final players = [
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 15,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p0',
      displayName: 'Bob',
      isGuest: true,
      userId: null,
      seatOrder: 0,
      totalScore: 25,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p2',
      displayName: 'Carla',
      isGuest: true,
      userId: null,
      seatOrder: 2,
      totalScore: 5,
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
      scoresDelta: scoresDelta,
      createdAt: DateTime(2026),
      closedAt: DateTime(2026),
    );
  }

  setUp(() {
    gameRepository = MockGameRepository();
    roundRepository = MockRoundRepository();
    useCase = GetGameScorecardUseCase(gameRepository, roundRepository);
  });

  test('computes cumulative scores round by round', () async {
    final rounds = [
      closedRound(
        number: 1,
        cards: 1,
        bids: const {'p0': 1, 'p1': 0, 'p2': 0},
        scoresDelta: const {'p0': 11, 'p1': -10, 'p2': -10},
      ),
      closedRound(
        number: 2,
        cards: 2,
        bids: const {'p0': 0, 'p1': 2, 'p2': 1},
        scoresDelta: const {'p0': -10, 'p1': 12, 'p2': 11},
      ),
      Round(
        id: 'round-3',
        gameId: 'game-1',
        roundNumber: 3,
        cardsInRound: 3,
        dealerPlayerId: 'p0',
        status: RoundStatus.bidding,
        bids: const {'p0': 1},
        createdAt: DateTime(2026),
      ),
    ];

    when(gameRepository.getGameById('game-1')).thenAnswer((_) async => game);
    when(roundRepository.getRoundsByGameId('game-1'))
        .thenAnswer((_) async => rounds);

    final scorecard = await useCase(gameId: 'game-1');

    expect(scorecard.players.map((p) => p.id), ['p0', 'p1', 'p2']);
    expect(scorecard.rows, hasLength(3));

    final row1 = scorecard.rows[0];
    expect(row1.roundNumber, 1);
    expect(row1.cardsInRound, 1);
    expect(row1.isCurrent, isFalse);
    expect(row1.bids, {'p0': 1, 'p1': 0, 'p2': 0});
    expect(row1.cumulative, {'p0': 11, 'p1': -10, 'p2': -10});

    final row2 = scorecard.rows[1];
    expect(row2.roundNumber, 2);
    expect(row2.isCurrent, isFalse);
    expect(row2.cumulative, {'p0': 1, 'p1': 2, 'p2': 1});

    final row3 = scorecard.rows[2];
    expect(row3.roundNumber, 3);
    expect(row3.isCurrent, isTrue);
    expect(row3.bids, {'p0': 1, 'p1': null, 'p2': null});
    expect(row3.cumulative, {'p0': null, 'p1': null, 'p2': null});
  });

  test('includes only closed rounds when game is finished', () async {
    final finishedGame = Game(
      id: 'game-1',
      status: GameStatus.finished,
      playerCount: 3,
      totalCards: 40,
      maxCardsPerRound: 10,
      roundSequence: const [
        RoundDefinition(roundNumber: 1, cardsPerPlayer: 1),
        RoundDefinition(roundNumber: 2, cardsPerPlayer: 2),
      ],
      players: players,
      currentRoundNumber: 2,
      startedAt: DateTime(2026),
      finishedAt: DateTime(2026, 1, 2),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final rounds = [
      closedRound(
        number: 1,
        cards: 1,
        bids: const {'p0': 0, 'p1': 1, 'p2': 0},
        scoresDelta: const {'p0': -10, 'p1': 11, 'p2': -10},
      ),
      closedRound(
        number: 2,
        cards: 2,
        bids: const {'p0': 1, 'p1': 0, 'p2': 1},
        scoresDelta: const {'p0': 11, 'p1': -10, 'p2': 11},
      ),
    ];

    when(gameRepository.getGameById('game-1'))
        .thenAnswer((_) async => finishedGame);
    when(roundRepository.getRoundsByGameId('game-1'))
        .thenAnswer((_) async => rounds);

    final scorecard = await useCase(gameId: 'game-1');

    expect(scorecard.rows, hasLength(2));
    expect(scorecard.rows.every((row) => !row.isCurrent), isTrue);
    expect(scorecard.rows[1].cumulative, {'p0': 1, 'p1': 1, 'p2': 1});
  });

  test('throws when game is not found', () async {
    when(gameRepository.getGameById('missing')).thenAnswer((_) async => null);

    expect(
      () => useCase(gameId: 'missing'),
      throwsA(isA<StateError>()),
    );
  });
}
