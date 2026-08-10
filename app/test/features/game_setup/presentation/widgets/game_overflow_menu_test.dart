import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/cancel_game_usecase.dart';
import 'package:la_pocha/features/game_setup/presentation/bloc/cancel_game_cubit.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/game_overflow_menu.dart';
import 'package:la_pocha/features/round/domain/usecases/repeat_round_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/repeat_round_cubit.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'game_overflow_menu_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<CancelGameUseCase>(),
  MockSpec<RepeatRoundUseCase>(),
])
void main() {
  late MockCancelGameUseCase cancelGame;
  late MockRepeatRoundUseCase repeatRound;
  final getIt = GetIt.instance;

  final resetRound = Round(
    id: 'round-1',
    gameId: 'game-1',
    roundNumber: 1,
    cardsInRound: 4,
    dealerPlayerId: 'p1',
    status: RoundStatus.bidding,
    bids: const {},
    createdAt: DateTime(2026),
  );

  setUp(() async {
    cancelGame = MockCancelGameUseCase();
    repeatRound = MockRepeatRoundUseCase();
    when(cancelGame(gameId: anyNamed('gameId'))).thenAnswer((_) async {});
    when(
      repeatRound(gameId: anyNamed('gameId'), roundNumber: anyNamed('roundNumber')),
    ).thenAnswer((_) async => resetRound);

    await getIt.reset();
    getIt.registerFactory<CancelGameUseCase>(() => cancelGame);
    getIt.registerFactory<CancelGameCubit>(
      () => CancelGameCubit(cancelGame: getIt()),
    );
    getIt.registerFactory<RepeatRoundUseCase>(() => repeatRound);
    getIt.registerFactory<RepeatRoundCubit>(
      () => RepeatRoundCubit(repeatRound: getIt()),
    );
  });

  Widget buildApp({int? repeatRoundNumber}) {
    final router = GoRouter(
      initialLocation: '/game',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('HOME SCREEN')),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) => Scaffold(
            body: SafeArea(
              child: GameOverflowMenu(
                gameId: 'game-1',
                repeatRoundNumber: repeatRoundNumber,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/games/:gameId/rounds/:roundNumber/bids',
          builder: (context, state) => const Scaffold(
            body: Text('BIDDING SCREEN'),
          ),
        ),
        GoRoute(
          path: '/games/:gameId/scorecard',
          builder: (context, state) => const Scaffold(
            body: Text('SCORECARD SCREEN'),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
  }

  Future<void> openMenuAndTapCancel(WidgetTester tester) async {
    await openMenu(tester);
    await tester.tap(find.text('Cancelar partida').last);
    await tester.pumpAndSettle();
  }

  testWidgets('shows overflow menu without repeatRoundNumber', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);

    await openMenu(tester);
    expect(find.text('Ver tabla de puntos'), findsOneWidget);
    expect(find.text('Cancelar partida'), findsOneWidget);
    expect(find.text('Repetir ronda'), findsNothing);
  });

  testWidgets('navigates to scorecard from overflow menu', (tester) async {
    await tester.pumpWidget(buildApp());
    await openMenu(tester);
    await tester.tap(find.text('Ver tabla de puntos'));
    await tester.pumpAndSettle();

    expect(find.text('SCORECARD SCREEN'), findsOneWidget);
  });

  testWidgets('shows confirmation dialog when tapping cancel in menu', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await openMenuAndTapCancel(tester);

    expect(find.text('Volver'), findsOneWidget);
    expect(
      find.textContaining('Se perdera todo el progreso'),
      findsOneWidget,
    );
  });

  testWidgets('does not delete the game when confirmation is dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await openMenuAndTapCancel(tester);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    verifyNever(cancelGame(gameId: anyNamed('gameId')));
    expect(find.text('HOME SCREEN'), findsNothing);
  });

  testWidgets('deletes the game and navigates home when confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await openMenuAndTapCancel(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar partida'));
    await tester.pumpAndSettle();

    verify(cancelGame(gameId: 'game-1')).called(1);
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });

  testWidgets('shows overflow menu when repeatRoundNumber is set', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(repeatRoundNumber: 1));
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);

    await openMenu(tester);
    expect(find.text('Ver tabla de puntos'), findsOneWidget);
    expect(find.text('Repetir ronda'), findsOneWidget);
    expect(find.text('Cancelar partida'), findsOneWidget);
  });

  testWidgets('shows repeat round confirmation dialog', (tester) async {
    await tester.pumpWidget(buildApp(repeatRoundNumber: 1));
    await openMenu(tester);
    await tester.tap(find.text('Repetir ronda'));
    await tester.pumpAndSettle();

    expect(find.text('Volver'), findsOneWidget);
    expect(
      find.textContaining('Se perderan las apuestas'),
      findsOneWidget,
    );
  });

  testWidgets('does not repeat round when confirmation is dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(repeatRoundNumber: 1));
    await openMenu(tester);
    await tester.tap(find.text('Repetir ronda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    verifyNever(
      repeatRound(
        gameId: anyNamed('gameId'),
        roundNumber: anyNamed('roundNumber'),
      ),
    );
    expect(find.text('BIDDING SCREEN'), findsNothing);
  });

  testWidgets('repeats round and navigates to bidding when confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(repeatRoundNumber: 1));
    await openMenu(tester);
    await tester.tap(find.text('Repetir ronda'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Repetir ronda'));
    await tester.pumpAndSettle();

    verify(repeatRound(gameId: 'game-1', roundNumber: 1)).called(1);
    expect(find.text('BIDDING SCREEN'), findsOneWidget);
  });

  testWidgets('shows cancel in overflow menu when repeat is available', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(repeatRoundNumber: 1));

    await openMenuAndTapCancel(tester);

    expect(find.text('Volver'), findsOneWidget);
    expect(
      find.textContaining('Se perdera todo el progreso'),
      findsOneWidget,
    );
  });
}
