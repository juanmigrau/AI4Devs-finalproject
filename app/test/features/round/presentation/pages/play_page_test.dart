import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/cancel_game_usecase.dart';
import 'package:la_pocha/features/game_setup/presentation/bloc/cancel_game_cubit.dart';
import 'package:la_pocha/features/round/domain/usecases/repeat_round_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/repeat_round_cubit.dart';
import 'package:la_pocha/features/round/domain/entities/round_play_state.dart';
import 'package:la_pocha/features/round/domain/usecases/correct_bids_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/get_round_play_state_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/revert_round_to_bidding_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/play_state_bloc.dart';
import 'package:la_pocha/features/round/presentation/pages/play_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'play_page_test.mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

@GenerateNiceMocks([
  MockSpec<GetRoundPlayStateUseCase>(),
  MockSpec<CorrectBidsUseCase>(),
  MockSpec<CancelGameUseCase>(),
  MockSpec<RepeatRoundUseCase>(),
  MockSpec<RevertRoundToBiddingUseCase>(),
])
void main() {
  late MockGetRoundPlayStateUseCase getRoundPlayState;
  late MockCorrectBidsUseCase correctBids;
  late MockCancelGameUseCase cancelGame;
  late MockRepeatRoundUseCase repeatRound;
  late MockRevertRoundToBiddingUseCase revertRoundToBidding;
  late MockAuthBloc authBloc;
  final getIt = GetIt.instance;

  provideDummy<AuthState>(const Unauthenticated());

  final players = [
    PlayerEmbed(
      id: 'p0',
      displayName: 'Dealer',
      isGuest: true,
      userId: null,
      seatOrder: 0,
      totalScore: 42,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 38,
      joinedAt: DateTime(2026),
    ),
  ];

  final game = Game(
    id: 'game-1',
    status: GameStatus.inProgress,
    playerCount: 2,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [RoundDefinition(roundNumber: 1, cardsPerPlayer: 4)],
    players: players,
    currentRoundNumber: 1,
    startedAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final round = Round(
    id: 'round-1',
    gameId: 'game-1',
    roundNumber: 1,
    cardsInRound: 4,
    dealerPlayerId: 'p0',
    status: RoundStatus.playing,
    bids: const {'p0': 0, 'p1': 2},
    createdAt: DateTime(2026),
  );

  final playState = RoundPlayState(
    game: game,
    round: round,
    players: players,
    bidSum: 2,
    restrictionMet: true,
  );

  setUp(() async {
    getRoundPlayState = MockGetRoundPlayStateUseCase();
    when(
      getRoundPlayState(
        gameId: anyNamed('gameId'),
        roundNumber: anyNamed('roundNumber'),
      ),
    ).thenAnswer((_) async => playState);

    correctBids = MockCorrectBidsUseCase();
    authBloc = MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const Unauthenticated(),
    );
    cancelGame = MockCancelGameUseCase();
    repeatRound = MockRepeatRoundUseCase();
    revertRoundToBidding = MockRevertRoundToBiddingUseCase();
    when(
      revertRoundToBidding(
        gameId: anyNamed('gameId'),
        roundNumber: anyNamed('roundNumber'),
      ),
    ).thenAnswer((_) async => round.copyWith(status: RoundStatus.bidding));

    await getIt.reset();
    getIt.registerFactory<GetRoundPlayStateUseCase>(() => getRoundPlayState);
    getIt.registerFactory<CorrectBidsUseCase>(() => correctBids);
    getIt.registerFactory<RevertRoundToBiddingUseCase>(
      () => revertRoundToBidding,
    );
    getIt.registerFactory<PlayStateBloc>(
      () => PlayStateBloc(getRoundPlayState: getIt(), correctBids: getIt()),
    );
    getIt.registerFactory<CancelGameUseCase>(() => cancelGame);
    getIt.registerFactory<CancelGameCubit>(
      () => CancelGameCubit(cancelGame: getIt()),
    );
    getIt.registerFactory<RepeatRoundUseCase>(() => repeatRound);
    getIt.registerFactory<RepeatRoundCubit>(
      () => RepeatRoundCubit(repeatRound: getIt()),
    );
  });

  testWidgets('renders bids, scores and balance banner with mock data', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PlayPage(gameId: 'game-1', roundNumber: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dealer'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    expect(find.text('-2'), findsOneWidget);
    expect(find.text('Balance de bazas'), findsOneWidget);
    expect(find.text('Bazas'), findsOneWidget);
    expect(find.text('Pts'), findsOneWidget);
    expect(find.text('Introducir bazas reales'), findsOneWidget);
    expect(find.text('Corregir apuestas'), findsNothing);
    expect(find.text('En juego'), findsOneWidget);
  });

  testWidgets(
    'back button reverts round to bidding before navigating to bids',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/games/game-1/rounds/1/play',
        routes: [
          GoRoute(
            path: '/games/:gameId/rounds/:roundNumber/play',
            builder: (context, state) =>
                const PlayPage(gameId: 'game-1', roundNumber: 1),
          ),
          GoRoute(
            path: '/games/:gameId/rounds/:roundNumber/bids',
            builder: (context, state) =>
                const Scaffold(body: Text('BIDDING SCREEN')),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      verify(revertRoundToBidding(gameId: 'game-1', roundNumber: 1)).called(1);
      expect(find.text('BIDDING SCREEN'), findsOneWidget);
    },
  );
}
