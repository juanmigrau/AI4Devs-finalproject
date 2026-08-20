import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:la_pocha/features/favorites/domain/entities/favorite_player.dart';
import 'package:la_pocha/features/favorites/domain/usecases/add_favorite_usecase.dart';
import 'package:la_pocha/features/favorites/domain/usecases/get_favorites_usecase.dart';
import 'package:la_pocha/features/favorites/domain/usecases/remove_favorite_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/start_game_result.dart';
import 'package:la_pocha/features/game_setup/domain/entities/user_search_result.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/user_search_repository.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_player_from_favorite_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_player_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_registered_player_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/get_game_by_id_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/remove_player_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/search_users_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/update_player_name_usecase.dart';
import 'package:la_pocha/features/game_setup/presentation/bloc/add_players_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'add_players_bloc_test.mocks.dart';

class _FakeUserSearchRepository implements UserSearchRepository {
  List<UserSearchResult> results = const [];
  Object? errorToThrow;
  int callCount = 0;
  String? lastQuery;
  String? lastExcludeUid;

  @override
  Future<List<UserSearchResult>> searchUsers(
    String query, {
    String? excludeUid,
  }) async {
    callCount++;
    lastQuery = query;
    lastExcludeUid = excludeUid;
    final error = errorToThrow;
    if (error != null) {
      throw error;
    }
    return results;
  }
}

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

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity() : results = const [ConnectivityResult.wifi];

  List<ConnectivityResult> results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

@GenerateNiceMocks([
  MockSpec<GetGameByIdUseCase>(),
  MockSpec<GetFavoritesUseCase>(),
  MockSpec<GetCurrentUserUseCase>(),
  MockSpec<AddPlayerUseCase>(),
  MockSpec<AddPlayerFromFavoriteUseCase>(),
  MockSpec<RemovePlayerUseCase>(),
  MockSpec<UpdatePlayerNameUseCase>(),
  MockSpec<AddFavoriteUseCase>(),
  MockSpec<RemoveFavoriteUseCase>(),
])
void main() {
  late MockGetGameByIdUseCase getGameById;
  late MockGetFavoritesUseCase getFavorites;
  late MockGetCurrentUserUseCase getCurrentUser;
  late MockAddPlayerUseCase addPlayer;
  late MockAddPlayerFromFavoriteUseCase addPlayerFromFavorite;
  late MockRemovePlayerUseCase removePlayer;
  late MockUpdatePlayerNameUseCase updatePlayerName;
  late MockAddFavoriteUseCase addFavorite;
  late MockRemoveFavoriteUseCase removeFavorite;
  late _FakeGameRepository gameRepository;
  late _FakeUserSearchRepository userSearchRepository;
  late _FakeConnectivity connectivity;
  late SearchUsersUseCase searchUsers;
  late AddRegisteredPlayerUseCase addRegisteredPlayer;

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

  final currentUserProfile = UserProfile(
    uid: 'uid-1',
    displayName: 'Juan',
    email: 'juan@test.com',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    getGameById = MockGetGameByIdUseCase();
    getFavorites = MockGetFavoritesUseCase();
    getCurrentUser = MockGetCurrentUserUseCase();
    addPlayer = MockAddPlayerUseCase();
    addPlayerFromFavorite = MockAddPlayerFromFavoriteUseCase();
    removePlayer = MockRemovePlayerUseCase();
    updatePlayerName = MockUpdatePlayerNameUseCase();
    addFavorite = MockAddFavoriteUseCase();
    removeFavorite = MockRemoveFavoriteUseCase();
    gameRepository = _FakeGameRepository()..game = baseGame;
    userSearchRepository = _FakeUserSearchRepository();
    connectivity = _FakeConnectivity();
    searchUsers = SearchUsersUseCase(userSearchRepository);
    addRegisteredPlayer = AddRegisteredPlayerUseCase(gameRepository);
    when(getCurrentUser()).thenAnswer((_) async => null);
  });

  AddPlayersBloc buildBloc() => AddPlayersBloc(
    getGameById: getGameById,
    getFavorites: getFavorites,
    getCurrentUser: getCurrentUser,
    addPlayer: addPlayer,
    addPlayerFromFavorite: addPlayerFromFavorite,
    addRegisteredPlayer: addRegisteredPlayer,
    searchUsers: searchUsers,
    removePlayer: removePlayer,
    updatePlayerName: updatePlayerName,
    addFavorite: addFavorite,
    removeFavorite: removeFavorite,
    connectivity: connectivity,
  );

  final favoriteAna = FavoritePlayer(
    id: 'fav-ana',
    displayName: 'Ana',
    userId: null,
    createdAt: DateTime(2026),
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'loads game and favorites on start',
    build: buildBloc,
    setUp: () {
      when(getGameById('game-1')).thenAnswer((_) async => baseGame);
      when(getFavorites()).thenAnswer((_) async => [favoriteAna]);
    },
    act: (bloc) => bloc.add(const AddPlayersStarted(gameId: 'game-1')),
    expect: () => [
      const AddPlayersLoading(),
      AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [],
        favorites: [favoriteAna],
        currentUser: null,
        activeEditIndex: null,
        isLoading: false,
      ),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'includes current user in loaded state when session is active',
    build: buildBloc,
    setUp: () {
      when(getGameById('game-1')).thenAnswer((_) async => baseGame);
      when(getFavorites()).thenAnswer((_) async => [favoriteAna]);
      when(getCurrentUser()).thenAnswer((_) async => currentUserProfile);
    },
    act: (bloc) => bloc.add(const AddPlayersStarted(gameId: 'game-1')),
    expect: () => [
      const AddPlayersLoading(),
      AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [],
        favorites: [favoriteAna],
        currentUser: currentUserProfile,
        activeEditIndex: null,
        isLoading: false,
      ),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'adds current user as registered player from chip without favorite lookup',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: const [],
      currentUser: currentUserProfile,
      activeEditIndex: null,
      isLoading: false,
    ),
    setUp: () {
      final currentUserFavorite = FavoritePlayer(
        id: 'uid-1',
        displayName: 'Juan',
        userId: 'uid-1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final player = PlayerEmbed(
        id: 'p1',
        displayName: 'Juan',
        isGuest: false,
        userId: 'uid-1',
        seatOrder: 0,
        totalScore: 0,
        joinedAt: DateTime(2026),
      );
      when(
        addPlayerFromFavorite(
          gameId: 'game-1',
          favoriteId: 'uid-1',
          favorite: currentUserFavorite,
        ),
      ).thenAnswer((_) async => baseGame.copyWith(players: [player]));
    },
    act: (bloc) => bloc.add(
      FavoriteChipTapped(
        favorite: FavoritePlayer(
          id: 'uid-1',
          displayName: 'Juan',
          userId: 'uid-1',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ),
    ),
    expect: () => [
      AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [],
        favorites: const [],
        currentUser: currentUserProfile,
        activeEditIndex: null,
        isLoading: true,
      ),
      AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [
          PlayerEmbed(
            id: 'p1',
            displayName: 'Juan',
            isGuest: false,
            userId: 'uid-1',
            seatOrder: 0,
            totalScore: 0,
            joinedAt: DateTime(2026),
          ),
        ],
        favorites: const [],
        currentUser: currentUserProfile,
        activeEditIndex: null,
        isLoading: false,
      ),
    ],
    verify: (_) {
      verifyNever(getFavorites());
      verifyNever(
        addFavorite(
          displayName: anyNamed('displayName'),
          userId: anyNamed('userId'),
        ),
      );
    },
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'adds player from favorite chip and updates players',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [favoriteAna],
      activeEditIndex: null,
      isLoading: false,
    ),
    setUp: () {
      final player = PlayerEmbed(
        id: 'p1',
        displayName: 'Ana',
        isGuest: true,
        userId: null,
        seatOrder: 0,
        totalScore: 0,
        joinedAt: DateTime(2026),
      );
      when(
        addPlayer(gameId: 'game-1', name: 'Ana'),
      ).thenAnswer((_) async => baseGame.copyWith(players: [player]));
      when(
        addPlayerFromFavorite(gameId: 'game-1', favoriteId: 'fav-ana'),
      ).thenAnswer((_) async => baseGame.copyWith(players: [player]));
    },
    act: (bloc) => bloc.add(FavoriteChipTapped(favorite: favoriteAna)),
    expect: () => [
      AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [],
        favorites: [favoriteAna],
        activeEditIndex: null,
        isLoading: true,
      ),
      AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [
          PlayerEmbed(
            id: 'p1',
            displayName: 'Ana',
            isGuest: true,
            userId: null,
            seatOrder: 0,
            totalScore: 0,
            joinedAt: DateTime(2026),
          ),
        ],
        favorites: [favoriteAna],
        activeEditIndex: null,
        isLoading: false,
      ),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'toggles player favorite on and off',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'Ana',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
      favorites: const [],
      activeEditIndex: null,
      isLoading: false,
    ),
    setUp: () {
      when(
        addFavorite(displayName: 'Ana', userId: null),
      ).thenAnswer((_) async => favoriteAna);
      when(removeFavorite('fav-ana')).thenAnswer((_) async {});
    },
    act: (bloc) async {
      bloc.add(const PlayerFavoriteToggled(playerId: 'p1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const PlayerFavoriteToggled(playerId: 'p1'));
    },
    expect: () => [
      isA<AddPlayersLoaded>().having((s) => s.isLoading, 'loading', true),
      isA<AddPlayersLoaded>()
          .having((s) => s.favorites.length, 'favorites', 1)
          .having((s) => s.isLoading, 'loading', false),
      isA<AddPlayersLoaded>().having((s) => s.isLoading, 'loading', true),
      isA<AddPlayersLoaded>()
          .having((s) => s.favorites.isEmpty, 'favorites', true)
          .having((s) => s.isLoading, 'loading', false),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'removes player and keeps favorite to re-show chip',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'Ana',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
      favorites: [favoriteAna],
      activeEditIndex: null,
      isLoading: false,
    ),
    setUp: () {
      when(
        removePlayer(gameId: 'game-1', playerId: 'p1'),
      ).thenAnswer((_) async => baseGame.copyWith(players: const []));
    },
    act: (bloc) => bloc.add(const PlayerRemoved(playerId: 'p1')),
    expect: () => [
      AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [
          PlayerEmbed(
            id: 'p1',
            displayName: 'Ana',
            isGuest: true,
            userId: null,
            seatOrder: 0,
            totalScore: 0,
            joinedAt: DateTime(2026),
          ),
        ],
        favorites: [favoriteAna],
        activeEditIndex: null,
        isLoading: true,
      ),
      AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [],
        favorites: [favoriteAna],
        activeEditIndex: null,
        isLoading: false,
      ),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'activates and cancels inline edit slot',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: null,
      isLoading: false,
    ),
    act: (bloc) async {
      bloc.add(const EditSlotActivated(index: 0));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const EditSlotCancelled());
    },
    expect: () => [
      const AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [],
        favorites: [],
        activeEditIndex: 0,
        isLoading: false,
      ),
      const AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [],
        favorites: [],
        activeEditIndex: null,
        isLoading: false,
      ),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'confirms player name from inline edit',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: 0,
      isLoading: false,
    ),
    setUp: () {
      final player = PlayerEmbed(
        id: 'p1',
        displayName: 'Ana',
        isGuest: true,
        userId: null,
        seatOrder: 0,
        totalScore: 0,
        joinedAt: DateTime(2026),
      );
      when(
        addPlayer(gameId: 'game-1', name: 'Ana'),
      ).thenAnswer((_) async => baseGame.copyWith(players: [player]));
    },
    act: (bloc) => bloc.add(const PlayerNameConfirmed(index: 0, name: 'Ana')),
    expect: () => [
      const AddPlayersLoaded(
        gameId: 'game-1',
        playerCount: 4,
        players: [],
        favorites: [],
        activeEditIndex: 0,
        isLoading: true,
      ),
      isA<AddPlayersLoaded>()
          .having((s) => s.players.length, 'players', 1)
          .having((s) => s.activeEditIndex, 'activeEditIndex', null)
          .having((s) => s.isLoading, 'isLoading', false),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'emits empty-name error then clears it so SnackBar is one-shot',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: 0,
      isLoading: false,
    ),
    act: (bloc) => bloc.add(const PlayerNameConfirmed(index: 0, name: '   ')),
    expect: () => [
      isA<AddPlayersLoaded>().having(
        (s) => s.errorMessage,
        'errorMessage',
        'El nombre no puede estar vacío',
      ),
      isA<AddPlayersLoaded>().having(
        (s) => s.errorMessage,
        'errorMessage',
        isNull,
      ),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'emits duplicate-name error then clears it so SnackBar is one-shot',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'Ana',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
      favorites: const [],
      activeEditIndex: 1,
      isLoading: false,
    ),
    setUp: () {
      when(addPlayer(gameId: 'game-1', name: 'Ana')).thenThrow(
        ArgumentError.value(
          'Ana',
          'name',
          'Player name already exists in this game',
        ),
      );
    },
    act: (bloc) => bloc.add(const PlayerNameConfirmed(index: 1, name: 'Ana')),
    expect: () => [
      isA<AddPlayersLoaded>().having((s) => s.isLoading, 'loading', true),
      isA<AddPlayersLoaded>()
          .having(
            (s) => s.errorMessage,
            'errorMessage',
            'Ya hay un jugador con ese nombre en esta partida.',
          )
          .having((s) => s.isLoading, 'isLoading', false),
      isA<AddPlayersLoaded>()
          .having((s) => s.errorMessage, 'errorMessage', isNull)
          .having((s) => s.isLoading, 'isLoading', false),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'clears prior error before successful confirm so listener does not re-fire',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: 0,
      isLoading: false,
      errorMessage: 'Ya hay un jugador con ese nombre en esta partida.',
    ),
    setUp: () {
      final player = PlayerEmbed(
        id: 'p1',
        displayName: 'Luis',
        isGuest: true,
        userId: null,
        seatOrder: 0,
        totalScore: 0,
        joinedAt: DateTime(2026),
      );
      when(
        addPlayer(gameId: 'game-1', name: 'Luis'),
      ).thenAnswer((_) async => baseGame.copyWith(players: [player]));
    },
    act: (bloc) => bloc.add(const PlayerNameConfirmed(index: 0, name: 'Luis')),
    expect: () => [
      isA<AddPlayersLoaded>()
          .having((s) => s.isLoading, 'loading', true)
          .having((s) => s.errorMessage, 'errorMessage', isNull),
      isA<AddPlayersLoaded>()
          .having((s) => s.players.length, 'players', 1)
          .having((s) => s.errorMessage, 'errorMessage', isNull)
          .having((s) => s.isLoading, 'isLoading', false),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'activates inline edit for existing player',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'Ana',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
      favorites: const [],
      activeEditIndex: null,
      isLoading: false,
    ),
    act: (bloc) => bloc.add(const PlayerEditActivated(playerId: 'p1')),
    expect: () => [
      isA<AddPlayersLoaded>().having(
        (s) => s.activeEditIndex,
        'activeEditIndex',
        0,
      ),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'exits edit without update when name is unchanged',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'Ana',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
      favorites: const [],
      activeEditIndex: 0,
      isLoading: false,
    ),
    act: (bloc) =>
        bloc.add(const PlayerNameUpdated(playerId: 'p1', newName: ' Ana ')),
    expect: () => [
      isA<AddPlayersLoaded>()
          .having((s) => s.activeEditIndex, 'activeEditIndex', null)
          .having((s) => s.players.first.displayName, 'name', 'Ana'),
    ],
    verify: (_) {
      verifyNever(
        updatePlayerName(
          gameId: anyNamed('gameId'),
          playerId: anyNamed('playerId'),
          newName: anyNamed('newName'),
        ),
      );
    },
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'emits empty-name error on update then clears it',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'Ana',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
      favorites: const [],
      activeEditIndex: 0,
      isLoading: false,
    ),
    act: (bloc) =>
        bloc.add(const PlayerNameUpdated(playerId: 'p1', newName: '  ')),
    expect: () => [
      isA<AddPlayersLoaded>().having(
        (s) => s.errorMessage,
        'errorMessage',
        'El nombre no puede estar vacío',
      ),
      isA<AddPlayersLoaded>().having(
        (s) => s.errorMessage,
        'errorMessage',
        isNull,
      ),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'updates existing player name from inline edit',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [
        PlayerEmbed(
          id: 'p1',
          displayName: 'Ana',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 0,
          joinedAt: DateTime(2026),
        ),
      ],
      favorites: const [],
      activeEditIndex: 0,
      isLoading: false,
    ),
    setUp: () {
      final updated = PlayerEmbed(
        id: 'p1',
        displayName: 'Anita',
        isGuest: true,
        userId: null,
        seatOrder: 0,
        totalScore: 0,
        joinedAt: DateTime(2026),
      );
      when(
        updatePlayerName(gameId: 'game-1', playerId: 'p1', newName: 'Anita'),
      ).thenAnswer((_) async => baseGame.copyWith(players: [updated]));
    },
    act: (bloc) =>
        bloc.add(const PlayerNameUpdated(playerId: 'p1', newName: 'Anita')),
    expect: () => [
      isA<AddPlayersLoaded>().having((s) => s.isLoading, 'loading', true),
      isA<AddPlayersLoaded>()
          .having((s) => s.players.first.displayName, 'name', 'Anita')
          .having((s) => s.activeEditIndex, 'activeEditIndex', null)
          .having((s) => s.isLoading, 'isLoading', false),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'UserSearchOpened activates search mode',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: null,
      isLoading: false,
    ),
    act: (bloc) => bloc.add(const UserSearchOpened()),
    expect: () => [
      isA<AddPlayersLoaded>()
          .having((s) => s.isUserSearchActive, 'searchActive', true)
          .having((s) => s.userSearchQuery, 'query', ''),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'UserSearchQueryChanged under 2 chars clears results without searching',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: null,
      isLoading: false,
      isUserSearchActive: true,
    ),
    act: (bloc) => bloc.add(const UserSearchQueryChanged(query: 'a')),
    expect: () => [
      isA<AddPlayersLoaded>()
          .having((s) => s.userSearchQuery, 'query', 'a')
          .having((s) => s.userSearchResults, 'results', isEmpty)
          .having((s) => s.userSearchLoading, 'loading', false),
    ],
    verify: (_) {
      expect(userSearchRepository.callCount, 0);
    },
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'UserSearchQueryChanged emits loading then results after debounce',
    build: buildBloc,
    seed: () => AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: const [],
      favorites: const [],
      activeEditIndex: null,
      isLoading: false,
      isUserSearchActive: true,
      currentUser: currentUserProfile,
    ),
    setUp: () {
      userSearchRepository.results = const [
        UserSearchResult(
          uid: 'u-ana',
          displayName: 'Ana',
          email: 'ana@gmail.com',
        ),
      ];
    },
    act: (bloc) => bloc.add(const UserSearchQueryChanged(query: 'an')),
    wait: const Duration(milliseconds: 350),
    expect: () => [
      isA<AddPlayersLoaded>().having((s) => s.userSearchQuery, 'query', 'an'),
      isA<AddPlayersLoaded>().having(
        (s) => s.userSearchLoading,
        'loading',
        true,
      ),
      isA<AddPlayersLoaded>()
          .having((s) => s.userSearchLoading, 'loading', false)
          .having((s) => s.userSearchResults, 'results', hasLength(1))
          .having((s) => s.userSearchResults.first.displayName, 'name', 'Ana'),
    ],
    verify: (_) {
      expect(userSearchRepository.callCount, 1);
      expect(userSearchRepository.lastExcludeUid, 'uid-1');
    },
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'UserSearchQueryChanged shows offline message without crashing',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: null,
      isLoading: false,
      isUserSearchActive: true,
    ),
    setUp: () {
      connectivity.results = [ConnectivityResult.none];
    },
    act: (bloc) => bloc.add(const UserSearchQueryChanged(query: 'an')),
    wait: const Duration(milliseconds: 350),
    expect: () => [
      isA<AddPlayersLoaded>().having((s) => s.userSearchQuery, 'query', 'an'),
      isA<AddPlayersLoaded>().having(
        (s) => s.userSearchError,
        'error',
        AddPlayersBloc.offlineSearchMessage,
      ),
    ],
    verify: (_) {
      expect(userSearchRepository.callCount, 0);
    },
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'UserSearchResultSelected adds registered player and closes search',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: null,
      isLoading: false,
      isUserSearchActive: true,
      userSearchQuery: 'an',
    ),
    setUp: () {
      gameRepository.game = baseGame;
    },
    act: (bloc) => bloc.add(
      const UserSearchResultSelected(
        user: UserSearchResult(
          uid: 'u-ana',
          displayName: 'Ana',
          email: 'ana@gmail.com',
        ),
      ),
    ),
    expect: () => [
      isA<AddPlayersLoaded>().having((s) => s.isLoading, 'loading', true),
      isA<AddPlayersLoaded>()
          .having((s) => s.players, 'players', hasLength(1))
          .having((s) => s.players.first.userId, 'userId', 'u-ana')
          .having((s) => s.players.first.isGuest, 'isGuest', false)
          .having((s) => s.isUserSearchActive, 'searchActive', false)
          .having((s) => s.isLoading, 'isLoading', false),
    ],
  );

  blocTest<AddPlayersBloc, AddPlayersState>(
    'UserSearchClosed resets search state',
    build: buildBloc,
    seed: () => const AddPlayersLoaded(
      gameId: 'game-1',
      playerCount: 4,
      players: [],
      favorites: [],
      activeEditIndex: null,
      isLoading: false,
      isUserSearchActive: true,
      userSearchQuery: 'an',
      userSearchResults: [
        UserSearchResult(
          uid: 'u-ana',
          displayName: 'Ana',
          email: 'ana@gmail.com',
        ),
      ],
    ),
    act: (bloc) => bloc.add(const UserSearchClosed()),
    expect: () => [
      isA<AddPlayersLoaded>()
          .having((s) => s.isUserSearchActive, 'searchActive', false)
          .having((s) => s.userSearchQuery, 'query', '')
          .having((s) => s.userSearchResults, 'results', isEmpty),
    ],
  );
}
