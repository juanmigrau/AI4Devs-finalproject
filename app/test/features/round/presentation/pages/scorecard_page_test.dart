import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/cancel_game_usecase.dart';
import 'package:la_pocha/features/game_setup/presentation/bloc/cancel_game_cubit.dart';
import 'package:la_pocha/features/round/domain/entities/scorecard_row.dart';
import 'package:la_pocha/features/round/domain/usecases/get_game_scorecard_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/repeat_round_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/repeat_round_cubit.dart';
import 'package:la_pocha/features/round/presentation/pages/scorecard_page.dart';
import 'package:la_pocha/features/round/presentation/widgets/round_header.dart';
import 'package:la_pocha/features/round/presentation/widgets/scorecard_table.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'scorecard_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetGameScorecardUseCase>(),
  MockSpec<CancelGameUseCase>(),
  MockSpec<RepeatRoundUseCase>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGetGameScorecardUseCase getGameScorecard;
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

  setUp(() async {
    await getIt.reset();
    getGameScorecard = MockGetGameScorecardUseCase();
    cancelGame = MockCancelGameUseCase();
    repeatRound = MockRepeatRoundUseCase();
    when(getGameScorecard(gameId: anyNamed('gameId')))
        .thenAnswer((_) async => scorecard);
    getIt.registerFactory<GetGameScorecardUseCase>(() => getGameScorecard);
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

  testWidgets('shows scorecard table with 3 players and 3 rounds',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ScorecardPage(gameId: 'game-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tabla de partida'), findsOneWidget);
    expect(find.byType(ScorecardTable), findsOneWidget);
    expect(find.text('ANA'), findsOneWidget);
    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('CAR'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('—'), findsWidgets);
    verify(getGameScorecard(gameId: 'game-1')).called(1);
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
