import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/round/domain/entities/round_result.dart';
import 'package:la_pocha/features/round/domain/usecases/advance_to_next_round_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/finish_game_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/get_round_result_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/repeat_round_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/revert_round_to_playing_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/repeat_round_cubit.dart';
import 'package:la_pocha/features/round/presentation/bloc/round_result_bloc.dart';
import 'package:la_pocha/features/round/presentation/pages/round_result_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'round_result_page_test.mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

@GenerateNiceMocks([
  MockSpec<GetRoundResultUseCase>(),
  MockSpec<AdvanceToNextRoundUseCase>(),
  MockSpec<FinishGameUseCase>(),
  MockSpec<RevertRoundToPlayingUseCase>(),
  MockSpec<CancelGameUseCase>(),
  MockSpec<RepeatRoundUseCase>(),
])
void main() {
  late MockGetRoundResultUseCase getRoundResult;
  late MockAdvanceToNextRoundUseCase advanceToNextRound;
  late MockFinishGameUseCase finishGame;
  late MockRevertRoundToPlayingUseCase revertRoundToPlaying;
  late MockCancelGameUseCase cancelGame;
  late MockRepeatRoundUseCase repeatRound;
  late MockAuthBloc authBloc;
  final getIt = GetIt.instance;

  provideDummy<AuthState>(const Unauthenticated());

  final players = [
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 0,
      totalScore: 20,
      joinedAt: DateTime(2026),
    ),
  ];

  final game = Game(
    id: 'game-1',
    status: GameStatus.inProgress,
    playerCount: 1,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [
      RoundDefinition(roundNumber: 1, cardsPerPlayer: 4),
      RoundDefinition(roundNumber: 2, cardsPerPlayer: 5),
    ],
    players: players,
    currentRoundNumber: 1,
    startedAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final closedRound = Round(
    id: 'round-1',
    gameId: 'game-1',
    roundNumber: 1,
    cardsInRound: 4,
    dealerPlayerId: 'p1',
    status: RoundStatus.closed,
    bids: const {'p1': 2},
    tricks: const {'p1': 2},
    scoresDelta: const {'p1': 10},
    createdAt: DateTime(2026),
    closedAt: DateTime(2026),
  );

  final result = RoundResult(
    game: game,
    round: closedRound,
    entries: [
      RankingEntry(
        player: players.first,
        rank: 1,
        roundScore: 10,
        totalScore: 20,
        positionDelta: 0,
      ),
    ],
    dealerDisplayName: 'Ana',
    isLastRound: false,
  );

  setUp(() async {
    getRoundResult = MockGetRoundResultUseCase();
    when(
      getRoundResult(
        gameId: anyNamed('gameId'),
        roundNumber: anyNamed('roundNumber'),
      ),
    ).thenAnswer((_) async => result);

    advanceToNextRound = MockAdvanceToNextRoundUseCase();
    finishGame = MockFinishGameUseCase();
    revertRoundToPlaying = MockRevertRoundToPlayingUseCase();
    cancelGame = MockCancelGameUseCase();
    repeatRound = MockRepeatRoundUseCase();
    authBloc = MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const Unauthenticated(),
    );

    await getIt.reset();
    getIt.registerFactory<GetRoundResultUseCase>(() => getRoundResult);
    getIt.registerFactory<AdvanceToNextRoundUseCase>(() => advanceToNextRound);
    getIt.registerFactory<FinishGameUseCase>(() => finishGame);
    getIt.registerFactory<RevertRoundToPlayingUseCase>(
      () => revertRoundToPlaying,
    );
    getIt.registerFactory<RoundResultBloc>(
      () => RoundResultBloc(
        getRoundResult: getIt(),
        advanceToNextRound: getIt(),
        finishGame: getIt(),
      ),
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

  Future<void> pumpPage(WidgetTester tester, {required bool readOnly}) {
    return tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: RoundResultPage(
            gameId: 'game-1',
            roundNumber: 1,
            readOnly: readOnly,
          ),
        ),
      ),
    );
  }

  testWidgets('shows next-round action when not read-only', (tester) async {
    await pumpPage(tester, readOnly: false);
    await tester.pumpAndSettle();

    expect(find.text('Siguiente ronda'), findsOneWidget);
    expect(find.text('Volver a apuestas'), findsNothing);
  });

  testWidgets('shows return-to-bids action in read-only mode', (tester) async {
    await pumpPage(tester, readOnly: true);
    await tester.pumpAndSettle();

    expect(find.text('Volver a apuestas'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('Siguiente ronda'), findsNothing);
  });
}
