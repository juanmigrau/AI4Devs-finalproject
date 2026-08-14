import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/database/app_database.dart';
import 'package:la_pocha/features/favorites/data/datasources/favorite_local_datasource.dart';
import 'package:la_pocha/features/favorites/data/repositories/favorite_repository_impl.dart';
import 'package:la_pocha/features/favorites/domain/entities/favorite_player.dart';
import 'package:la_pocha/features/game_setup/data/datasources/game_local_datasource.dart';
import 'package:la_pocha/features/game_setup/data/repositories/game_repository_impl.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_player_from_favorite_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/create_game_draft_usecase.dart';

void main() {
  late AppDatabase database;
  late AddPlayerFromFavoriteUseCase useCase;
  late CreateGameDraftUseCase createGame;
  late FavoriteRepositoryImpl favoriteRepository;

  setUp(() {
    database = AppDatabase.forTesting();
    final gameRepository = GameRepositoryImpl(GameLocalDatasource(database));
    favoriteRepository = FavoriteRepositoryImpl(
      FavoriteLocalDatasource(database),
    );
    createGame = CreateGameDraftUseCase(gameRepository);
    useCase = AddPlayerFromFavoriteUseCase(gameRepository, favoriteRepository);
  });

  tearDown(() async {
    await database.close();
  });

  test('adds guest player from favorite', () async {
    final game = await createGame(playerCount: 4);
    final favorite = await favoriteRepository.addFavorite(displayName: 'Ana');

    final updated = await useCase(gameId: game.id, favoriteId: favorite.id);

    expect(updated.players.length, 1);
    expect(updated.players.first.displayName, 'Ana');
    expect(updated.players.first.isGuest, isTrue);
    expect(updated.players.first.userId, isNull);
  });

  test('adds registered player from favorite', () async {
    final game = await createGame(playerCount: 4);
    final favorite = await favoriteRepository.addFavorite(
      displayName: 'Carlos',
      userId: 'user-1',
    );

    final updated = await useCase(gameId: game.id, favoriteId: favorite.id);

    expect(updated.players.length, 1);
    expect(updated.players.first.displayName, 'Carlos');
    expect(updated.players.first.isGuest, isFalse);
    expect(updated.players.first.userId, 'user-1');
  });

  test(
    'adds registered player from provided favorite without repository lookup',
    () async {
      final game = await createGame(playerCount: 4);
      final providedFavorite = FavoritePlayer(
        id: 'uid-1',
        displayName: 'Juan',
        userId: 'uid-1',
        createdAt: DateTime(2026),
      );

      final updated = await useCase(
        gameId: game.id,
        favoriteId: providedFavorite.id,
        favorite: providedFavorite,
      );

      expect(updated.players.length, 1);
      expect(updated.players.first.displayName, 'Juan');
      expect(updated.players.first.isGuest, isFalse);
      expect(updated.players.first.userId, 'uid-1');
      expect(await favoriteRepository.getFavorites(), isEmpty);
    },
  );

  test('rejects duplicate player in game', () async {
    final game = await createGame(playerCount: 4);
    final favorite = await favoriteRepository.addFavorite(displayName: 'Ana');
    await useCase(gameId: game.id, favoriteId: favorite.id);

    expect(
      () => useCase(gameId: game.id, favoriteId: favorite.id),
      throwsA(isA<ArgumentError>()),
    );
  });
}
