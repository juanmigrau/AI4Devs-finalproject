import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/warning_banner.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/history/domain/usecases/repeat_game_usecase.dart';
import 'package:la_pocha/features/history/presentation/bloc/repeat_game_cubit.dart';
import 'package:la_pocha/features/round/presentation/pages/game_final_result_page.dart';
import 'package:la_pocha/features/sync/domain/usecases/upload_finished_game_usecase.dart';
import 'package:la_pocha/features/sync/presentation/bloc/game_sync_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'game_final_result_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GameRepository>(),
  MockSpec<RoundRepository>(),
  MockSpec<RepeatGameUseCase>(),
  MockSpec<AuthBloc>(),
  MockSpec<GameSyncBloc>(),
])
void main() {
  late MockGameRepository gameRepository;
  late MockRoundRepository roundRepository;
  late MockRepeatGameUseCase repeatGame;
  late MockAuthBloc authBloc;
  late MockGameSyncBloc gameSyncBloc;
  final getIt = GetIt.instance;

  provideDummy<AuthState>(const AuthInitial());
  provideDummy<GameSyncState>(const GameSyncIdle());

  final players = [
    PlayerEmbed(
      id: 'p0',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 0,
      totalScore: 50,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p1',
      displayName: 'Bruno',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 30,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p2',
      displayName: 'Carla',
      isGuest: true,
      userId: null,
      seatOrder: 2,
      totalScore: 20,
      joinedAt: DateTime(2026),
    ),
  ];

  final game = Game(
    id: 'game-1',
    status: GameStatus.finished,
    playerCount: 3,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [
      RoundDefinition(roundNumber: 1, cardsPerPlayer: 4),
      RoundDefinition(roundNumber: 2, cardsPerPlayer: 3),
    ],
    players: players,
    currentRoundNumber: 2,
    startedAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final lastRound = Round(
    id: 'round-2',
    gameId: 'game-1',
    roundNumber: 2,
    cardsInRound: 3,
    dealerPlayerId: 'p0',
    status: RoundStatus.closed,
    bids: const {'p0': 1, 'p1': 1, 'p2': 0},
    scoresDelta: const {'p0': 10, 'p1': 5, 'p2': -5},
    createdAt: DateTime(2026),
  );

  setUp(() async {
    gameRepository = MockGameRepository();
    roundRepository = MockRoundRepository();
    repeatGame = MockRepeatGameUseCase();
    authBloc = MockAuthBloc();
    gameSyncBloc = MockGameSyncBloc();

    when(gameRepository.getGameById('game-1')).thenAnswer((_) async => game);
    when(
      roundRepository.getRoundByGameAndNumber('game-1', 2),
    ).thenAnswer((_) async => lastRound);

    when(authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(authBloc.close()).thenAnswer((_) async {});
    when(authBloc.state).thenReturn(
      Authenticated(
        UserProfile(
          uid: 'user-1',
          email: 'a@b.com',
          displayName: 'User',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ),
    );

    when(gameSyncBloc.stream).thenAnswer((_) => const Stream.empty());
    when(gameSyncBloc.close()).thenAnswer((_) async {});
    when(gameSyncBloc.state).thenReturn(const GameSyncIdle());

    await getIt.reset();
    getIt.registerLazySingleton<GameRepository>(() => gameRepository);
    getIt.registerLazySingleton<RoundRepository>(() => roundRepository);
    getIt.registerFactory<RepeatGameCubit>(
      () => RepeatGameCubit(repeatGame: repeatGame),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<GameSyncBloc>.value(value: gameSyncBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const GameFinalResultPage(gameId: 'game-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows final result layout without winner in app bar', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Resultado final'), findsOneWidget);
    expect(find.text('2 rondas'), findsOneWidget);
    expect(find.textContaining('Ganador:'), findsNothing);
    expect(find.text('🏆'), findsOneWidget);
    expect(find.text('Ana'), findsWidgets);
    expect(find.text('50 puntos'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Ronda'), findsNothing);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Carla'), findsOneWidget);
    expect(find.text('Nueva partida'), findsOneWidget);
    expect(find.text('Repetir partida'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('shows sync failure banner inline without OK action', (
    tester,
  ) async {
    when(gameSyncBloc.state).thenReturn(
      const GameSyncFailure(
        gameId: 'game-1',
        outcome: UploadFinishedGameOutcome.failed,
      ),
    );

    await pumpPage(tester);

    expect(
      find.text(
        'No se pudo sincronizar con la nube. Se reintentará automáticamente.',
      ),
      findsOneWidget,
    );
    expect(find.text('OK'), findsNothing);
    expect(find.byType(WarningBanner), findsWidgets);
  });

  testWidgets('shows sync in progress banner inline', (tester) async {
    when(gameSyncBloc.state).thenReturn(
      const GameSyncInProgress(gameId: 'game-1'),
    );

    await pumpPage(tester);

    expect(find.text('Sincronizando con la nube...'), findsOneWidget);
    expect(find.text('OK'), findsNothing);
  });

  testWidgets('hides sync banner when idle', (tester) async {
    await pumpPage(tester);

    expect(find.text('Sincronizando con la nube...'), findsNothing);
    expect(
      find.text(
        'No se pudo sincronizar con la nube. Se reintentará automáticamente.',
      ),
      findsNothing,
    );
  });
}
