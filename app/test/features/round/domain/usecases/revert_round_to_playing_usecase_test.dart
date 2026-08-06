import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/round/domain/usecases/revert_round_to_playing_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'revert_round_to_playing_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GameRepository>(),
  MockSpec<RoundRepository>(),
])
void main() {
  late MockGameRepository gameRepository;
  late MockRoundRepository roundRepository;
  late RevertRoundToPlayingUseCase useCase;

  final players = [
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 30,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p2',
      displayName: 'Bob',
      isGuest: true,
      userId: null,
      seatOrder: 2,
      totalScore: 25,
      joinedAt: DateTime(2026),
    ),
  ];

  final game = Game(
    id: 'game-1',
    status: GameStatus.inProgress,
    playerCount: 2,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [
      RoundDefinition(roundNumber: 1, cardsPerPlayer: 4),
      RoundDefinition(roundNumber: 2, cardsPerPlayer: 5),
    ],
    players: players,
    currentRoundNumber: 2,
    startedAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Round closedRound() {
    return Round(
      id: 'round-2',
      gameId: 'game-1',
      roundNumber: 2,
      cardsInRound: 5,
      dealerPlayerId: 'p2',
      status: RoundStatus.closed,
      bids: const {'p1': 2, 'p2': 3},
      tricks: const {'p1': 2, 'p2': 3},
      scoresDelta: const {'p1': 10, 'p2': 15},
      createdAt: DateTime(2026),
      closedAt: DateTime(2026, 1, 2),
    );
  }

  setUp(() {
    gameRepository = MockGameRepository();
    roundRepository = MockRoundRepository();
    useCase = RevertRoundToPlayingUseCase(gameRepository, roundRepository);
    when(gameRepository.getGameById('game-1')).thenAnswer((_) async => game);
  });

  test(
    'reopens closed round to playing, clears tricks/scoresDelta, reverts scores',
    () async {
      final round = closedRound();

      when(
        roundRepository.getRoundByGameAndNumber('game-1', 2),
      ).thenAnswer((_) async => round);

      when(
        gameRepository.repeatRoundAndRevertScores(
          resetRound: anyNamed('resetRound'),
          updatedPlayers: anyNamed('updatedPlayers'),
        ),
      ).thenAnswer((invocation) async {
        return invocation.namedArguments[#resetRound] as Round;
      });

      final result = await useCase(gameId: 'game-1', roundNumber: 2);

      expect(result.status, RoundStatus.playing);
      expect(result.bids, equals(const {'p1': 2, 'p2': 3}));
      expect(result.tricks, isEmpty);
      expect(result.scoresDelta, isEmpty);
      expect(result.closedAt, isNull);
      expect(result.dealerPlayerId, 'p2');
      expect(result.cardsInRound, 5);

      final captured = verify(
        gameRepository.repeatRoundAndRevertScores(
          resetRound: captureAnyNamed('resetRound'),
          updatedPlayers: captureAnyNamed('updatedPlayers'),
        ),
      ).captured;

      final updatedPlayers = captured[1] as List<PlayerEmbed>;
      expect(updatedPlayers[0].totalScore, 20);
      expect(updatedPlayers[1].totalScore, 10);
    },
  );

  test('throws when round is not found', () async {
    when(
      roundRepository.getRoundByGameAndNumber('game-1', 2),
    ).thenAnswer((_) async => null);

    expect(
      () => useCase(gameId: 'game-1', roundNumber: 2),
      throwsStateError,
    );
    verifyNever(
      gameRepository.repeatRoundAndRevertScores(
        resetRound: anyNamed('resetRound'),
        updatedPlayers: anyNamed('updatedPlayers'),
      ),
    );
  });

  test('throws when game is not found', () async {
    when(gameRepository.getGameById('game-1')).thenAnswer((_) async => null);

    expect(
      () => useCase(gameId: 'game-1', roundNumber: 2),
      throwsStateError,
    );
  });

  test('throws when round is not closed', () async {
    final round = Round(
      id: 'round-2',
      gameId: 'game-1',
      roundNumber: 2,
      cardsInRound: 5,
      dealerPlayerId: 'p2',
      status: RoundStatus.playing,
      bids: const {'p1': 2, 'p2': 3},
      createdAt: DateTime(2026),
    );

    when(
      roundRepository.getRoundByGameAndNumber('game-1', 2),
    ).thenAnswer((_) async => round);

    expect(
      () => useCase(gameId: 'game-1', roundNumber: 2),
      throwsStateError,
    );
    verifyNever(
      gameRepository.repeatRoundAndRevertScores(
        resetRound: anyNamed('resetRound'),
        updatedPlayers: anyNamed('updatedPlayers'),
      ),
    );
  });
}
