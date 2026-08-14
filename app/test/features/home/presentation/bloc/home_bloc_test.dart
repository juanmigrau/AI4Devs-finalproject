import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/usecases/get_recent_games_usecase.dart';
import 'package:la_pocha/features/home/presentation/bloc/home_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GetRecentGamesUseCase>()])
void main() {
  late MockGetRecentGamesUseCase getRecentGames;

  final items = [
    GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 8, 13, 20, 14),
      playerCount: 4,
      displayLabel: '13 ago 2026, 20:14 — Ana, Luis, Marta, Pedro',
      winnerName: 'Ana',
      winnerScore: 40,
    ),
  ];

  setUp(() {
    getRecentGames = MockGetRecentGamesUseCase();
  });

  HomeBloc buildBloc() => HomeBloc(getRecentGames: getRecentGames);

  blocTest<HomeBloc, HomeState>(
    'emits loaded when there are recent games',
    build: buildBloc,
    setUp: () {
      when(getRecentGames()).thenAnswer((_) => Stream.value(items));
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [const HomeLoading(), HomeLoaded(recentGames: items)],
  );

  blocTest<HomeBloc, HomeState>(
    'emits empty when there are no recent games',
    build: buildBloc,
    setUp: () {
      when(getRecentGames()).thenAnswer((_) => Stream.value([]));
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [const HomeLoading(), const HomeEmpty()],
  );

  blocTest<HomeBloc, HomeState>(
    'emits failure when the use case stream errors',
    build: buildBloc,
    setUp: () {
      when(getRecentGames()).thenAnswer(
        (_) => Stream.error(Exception('network error')),
      );
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const HomeLoading(),
      isA<HomeFailure>().having(
        (state) => state.message,
        'message',
        isNot(contains('[DEBUG]')),
      ),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'updates list when watch emits again after a deletion',
    build: buildBloc,
    setUp: () {
      when(getRecentGames()).thenAnswer(
        (_) => Stream.fromIterable([
          items,
          <GameHistoryItem>[],
        ]),
      );
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const HomeLoading(),
      HomeLoaded(recentGames: items),
      const HomeEmpty(),
    ],
  );
}
