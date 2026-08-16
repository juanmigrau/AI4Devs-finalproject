import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/start_game_result.dart';
import 'package:la_pocha/features/game_setup/domain/entities/user_search_result.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_registered_player_usecase.dart';

class _FakeGameRepository implements GameRepository {
  Game? game;
  List<PlayerEmbed>? lastUpdatedPlayers;

  @override
  Future<Game?> getGameById(String id) async => game;

  @override
  Future<Game> updateGamePlayers(
    String gameId,
    List<PlayerEmbed> players,
  ) async {
    lastUpdatedPlayers = players;
    final current = game!;
    game = current.copyWith(players: players);
    return game!;
  }

  @override
  Future<Game?> getInProgressGame() async => null;

  @override
  Future<Game> saveDraft(Game game) async => game;

  @override
  Future<void> deleteGame(String gameId) async {}

  @override
  Future<StartGameResult> startGame({
    required String gameId,
    required List<PlayerEmbed> players,
    required String firstDealerPlayerId,
    required Round firstRound,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> revertGameToSetup(String gameId) async {}

  @override
  Future<Round> closeRoundAndUpdateScores({
    required Round closedRound,
    required List<PlayerEmbed> updatedPlayers,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Round> repeatRoundAndRevertScores({
    required Round resetRound,
    required List<PlayerEmbed> updatedPlayers,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Round> advanceToNextRound({
    required Round nextRound,
    required int nextRoundNumber,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Game> finishGame({
    required String gameId,
    required DateTime finishedAt,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  late _FakeGameRepository repository;
  late AddRegisteredPlayerUseCase useCase;

  final baseGame = Game(
    id: 'game-1',
    status: GameStatus.setup,
    playerCount: 4,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [],
    players: const [],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  const user = UserSearchResult(
    uid: 'user-1',
    displayName: 'Carlos',
    email: 'carlos@gmail.com',
    photoUrl: 'https://example.com/photo.jpg',
  );

  setUp(() {
    repository = _FakeGameRepository()..game = baseGame;
    useCase = AddRegisteredPlayerUseCase(repository);
  });

  test('adds registered player with userId and isGuest false', () async {
    final game = await useCase(gameId: 'game-1', user: user);

    expect(game.players, hasLength(1));
    expect(game.players.first.displayName, 'Carlos');
    expect(game.players.first.isGuest, isFalse);
    expect(game.players.first.userId, 'user-1');
    expect(repository.lastUpdatedPlayers, hasLength(1));
  });

  test('rejects duplicate by userId', () async {
    repository.game = baseGame.copyWith(
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'Other Name',
          isGuest: false,
          userId: 'user-1',
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
    );

    expect(
      () => useCase(gameId: 'game-1', user: user),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.lastUpdatedPlayers, isNull);
  });

  test('rejects duplicate by displayName', () async {
    repository.game = baseGame.copyWith(
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'carlos',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
    );

    expect(
      () => useCase(gameId: 'game-1', user: user),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.lastUpdatedPlayers, isNull);
  });
}
