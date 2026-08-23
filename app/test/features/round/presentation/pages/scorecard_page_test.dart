import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/cancel_game_usecase.dart';
import 'package:la_pocha/features/game_setup/presentation/bloc/cancel_game_cubit.dart';
import 'package:la_pocha/features/round/domain/entities/game_curiosities.dart';
import 'package:la_pocha/features/round/domain/entities/game_stats.dart';
import 'package:la_pocha/features/round/domain/entities/player_game_stats.dart';
import 'package:la_pocha/features/round/domain/entities/scorecard_row.dart';
import 'package:la_pocha/features/round/domain/usecases/get_game_scorecard_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/get_game_stats_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/repeat_round_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/repeat_round_cubit.dart';
import 'package:la_pocha/features/round/presentation/pages/scorecard_page.dart';
import 'package:la_pocha/features/round/presentation/widgets/chart_mode_toggle.dart';
import 'package:la_pocha/features/round/presentation/widgets/game_progress_chart.dart';
import 'package:la_pocha/features/round/presentation/widgets/game_stats_tab.dart';
import 'package:la_pocha/features/round/presentation/widgets/round_header.dart';
import 'package:la_pocha/features/round/presentation/widgets/scorecard_table.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'scorecard_page_test.mocks.dart';

class StubGetGameStatsUseCase implements GetGameStatsUseCase {
  StubGetGameStatsUseCase(this._stats);

  GameStats _stats;

  // ignore: avoid_setters_without_getters
  set stats(GameStats value) => _stats = value;

  @override
  Future<GameStats> call({required String gameId}) async => _stats;
}

@GenerateNiceMocks([
  MockSpec<GetGameScorecardUseCase>(),
  MockSpec<CancelGameUseCase>(),
  MockSpec<RepeatRoundUseCase>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGetGameScorecardUseCase getGameScorecard;
  late StubGetGameStatsUseCase getGameStats;
  late MockCancelGameUseCase cancelGame;
  late MockRepeatRoundUseCase repeatRound;
  final getIt = GetIt.instance;

  final players = [
    PlayerEmbed(
      id: 'p0',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 0,
      totalScore: 11,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p1',
      displayName: 'Bob',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: -10,
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

  final scorecard = GameScorecard(
    players: players,
    rows: [
      ScorecardRow(
        roundNumber: 1,
        cardsInRound: 1,
        bids: const {'p0': 1, 'p1': 0, 'p2': 0},
        cumulative: const {'p0': 11, 'p1': -10, 'p2': -10},
        isCurrent: false,
      ),
      ScorecardRow(
        roundNumber: 2,
        cardsInRound: 2,
        bids: const {'p0': 0, 'p1': 2, 'p2': 1},
        cumulative: const {'p0': 1, 'p1': 2, 'p2': 1},
        isCurrent: false,
      ),
      ScorecardRow(
        roundNumber: 3,
        cardsInRound: 3,
        bids: const {'p0': 1, 'p1': null, 'p2': null},
        cumulative: const {'p0': null, 'p1': null, 'p2': null},
        isCurrent: true,
      ),
    ],
  );

  GameStats emptyStats({int closedRoundCount = 0}) {
    return GameStats(
      players: players,
      playerStats: players
          .map(
            (p) => PlayerGameStats(
              playerId: p.id,
              displayName: p.displayName,
              seatOrder: p.seatOrder,
              totalBids: 0,
              totalTricks: 0,
              accuracyPercent: null,
              currentStreak: 0,
              bestStreak: 0,
              bestRoundDelta: null,
              worstRoundDelta: null,
              averageScorePerRound: null,
            ),
          )
          .toList(),
      curiosities: const GameCuriosities.empty(),
      progressSeries: players
          .map(
            (p) => PlayerProgressSeries(
              playerId: p.id,
              displayName: p.displayName,
              seatOrder: p.seatOrder,
              points: const [],
            ),
          )
          .toList(),
      closedRoundCount: closedRoundCount,
    );
  }

  GameStats richStats() {
    final series = players
        .map(
          (p) => PlayerProgressSeries(
            playerId: p.id,
            displayName: p.displayName,
            seatOrder: p.seatOrder,
            points: List.generate(
              5,
              (i) => PlayerProgressPoint(
                roundNumber: i + 1,
                cumulativeScore: (i + 1) * (3 - p.seatOrder),
                position: p.seatOrder + 1,
              ),
            ),
          ),
        )
        .toList();

    return GameStats(
      players: players,
      playerStats: [
        const PlayerGameStats(
          playerId: 'p0',
          displayName: 'Ana',
          seatOrder: 0,
          totalBids: 5,
          totalTricks: 5,
          accuracyPercent: 80,
          currentStreak: 2,
          bestStreak: 3,
          bestRoundDelta: 12,
          worstRoundDelta: -10,
          averageScorePerRound: 4.5,
        ),
        const PlayerGameStats(
          playerId: 'p1',
          displayName: 'Bob',
          seatOrder: 1,
          totalBids: 3,
          totalTricks: 4,
          accuracyPercent: 60,
          currentStreak: 0,
          bestStreak: 2,
          bestRoundDelta: 11,
          worstRoundDelta: -10,
          averageScorePerRound: 1.0,
        ),
        const PlayerGameStats(
          playerId: 'p2',
          displayName: 'Carla',
          seatOrder: 2,
          totalBids: 2,
          totalTricks: 2,
          accuracyPercent: 40,
          currentStreak: 1,
          bestStreak: 1,
          bestRoundDelta: 10,
          worstRoundDelta: -10,
          averageScorePerRound: -1.0,
        ),
      ],
      curiosities: const GameCuriosities(
        mostEqualRoundNumber: 2,
        riskiestPlayerId: 'p0',
        riskiestPlayerName: 'Ana',
        mostConservativePlayerId: 'p2',
        mostConservativePlayerName: 'Carla',
      ),
      progressSeries: series,
      closedRoundCount: 5,
    );
  }

  setUp(() async {
    await getIt.reset();
    getGameScorecard = MockGetGameScorecardUseCase();
    getGameStats = StubGetGameStatsUseCase(richStats());
    cancelGame = MockCancelGameUseCase();
    repeatRound = MockRepeatRoundUseCase();
    when(getGameScorecard(gameId: anyNamed('gameId')))
        .thenAnswer((_) async => scorecard);
    getIt.registerFactory<GetGameScorecardUseCase>(() => getGameScorecard);
    getIt.registerFactory<GetGameStatsUseCase>(() => getGameStats);
    getIt.registerFactory<CancelGameUseCase>(() => cancelGame);
    getIt.registerFactory<CancelGameCubit>(
      () => CancelGameCubit(cancelGame: getIt()),
    );
    getIt.registerFactory<RepeatRoundUseCase>(() => repeatRound);
    getIt.registerFactory<RepeatRoundCubit>(
      () => RepeatRoundCubit(repeatRound: getIt()),
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      return null;
    });
  });

  tearDown(() async {
    await getIt.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('shows three tabs and scorecard table', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ScorecardPage(gameId: 'game-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tabla de partida'), findsOneWidget);
    expect(find.text('Tabla'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Gráfica'), findsOneWidget);
    expect(find.byType(ScorecardTable), findsOneWidget);
    expect(find.text('ANA'), findsOneWidget);
    verify(getGameScorecard(gameId: 'game-1')).called(1);
  });

  testWidgets('Stats and chart tabs show empty state with 0 closed rounds',
      (tester) async {
    getGameStats.stats = emptyStats();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ScorecardPage(gameId: 'game-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text(GameStatsTab.emptyMessage), findsOneWidget);

    await tester.tap(find.text('Gráfica'));
    await tester.pumpAndSettle();
    expect(find.text(GameProgressChart.emptyMessage), findsOneWidget);
  });

  testWidgets('Stats and chart tabs show empty state with 1 closed round',
      (tester) async {
    getGameStats.stats = emptyStats(closedRoundCount: 1);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ScorecardPage(gameId: 'game-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text(GameStatsTab.emptyMessage), findsOneWidget);

    await tester.tap(find.text('Gráfica'));
    await tester.pumpAndSettle();
    expect(find.text(GameProgressChart.emptyMessage), findsOneWidget);
  });

  testWidgets('Stats tab shows player cards and curiosities with N rounds',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ScorecardPage(gameId: 'game-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Clasificación por acierto'), findsOneWidget);
    expect(find.text('Ana'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Datos curiosos'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Datos curiosos'), findsOneWidget);
    expect(find.text('Jugador más arriesgado'), findsOneWidget);
  });

  testWidgets('chart tab renders LineChart and toggles mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ScorecardPage(gameId: 'game-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gráfica'));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(ChartModeToggle), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Posición'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LineChart), findsOneWidget);

    await tester.tap(find.text('Puntos'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders wide scorecard without overflow (8 players, 18 rounds)',
      (tester) async {
    final widePlayers = List.generate(
      8,
      (i) => PlayerEmbed(
        id: 'p$i',
        displayName: 'P$i',
        isGuest: true,
        userId: null,
        seatOrder: i,
        totalScore: i,
        joinedAt: DateTime(2026),
      ),
    );
    final wideRows = List.generate(
      18,
      (i) => ScorecardRow(
        roundNumber: i + 1,
        cardsInRound: (i % 10) + 1,
        bids: {for (final p in widePlayers) p.id: i % 3},
        cumulative: {for (final p in widePlayers) p.id: i * 2},
        isCurrent: false,
      ),
    );
    when(getGameScorecard(gameId: anyNamed('gameId'))).thenAnswer(
      (_) async => GameScorecard(players: widePlayers, rows: wideRows),
    );
    getGameStats.stats = GameStats(
      players: widePlayers,
      playerStats: const [],
      curiosities: const GameCuriosities.empty(),
      progressSeries: const [],
      closedRoundCount: 18,
    );

    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ScorecardPage(gameId: 'game-wide'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ScorecardTable), findsOneWidget);
  });

  testWidgets('RoundHeader scorecard menu uses push navigation',
      (tester) async {
    final locations = <String>[];
    final router = GoRouter(
      initialLocation: '/games/game-1/rounds/1/play',
      routes: [
        GoRoute(
          path: '/games/:gameId/rounds/:roundNumber/play',
          builder: (context, state) => Scaffold(
            body: RoundHeader(
              gameId: state.pathParameters['gameId']!,
              roundNumber: 1,
              cardsInRound: 4,
              subtitle: 'En juego',
            ),
          ),
        ),
        GoRoute(
          path: '/games/:gameId/scorecard',
          builder: (context, state) {
            locations.add(state.uri.toString());
            return const Scaffold(body: Text('Scorecard route'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver tabla de puntos'));
    await tester.pumpAndSettle();

    expect(find.text('Scorecard route'), findsOneWidget);
    expect(locations, ['/games/game-1/scorecard']);
    expect(router.canPop(), isTrue);
  });
}
