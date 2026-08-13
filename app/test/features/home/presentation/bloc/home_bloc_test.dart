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
      when(getRecentGames()).thenAnswer((_) async => items);
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    expect: () => [const HomeLoading(), HomeLoaded(recentGames: items)],
  );

  blocTest<HomeBloc, HomeState>(
    'emits empty when there are no recent games',
    build: buildBloc,
    setUp: () {
      when(getRecentGames()).thenAnswer((_) async => []);
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    expect: () => [const HomeLoading(), const HomeEmpty()],
  );

  blocTest<HomeBloc, HomeState>(
    'emits failure when the use case throws',
    build: buildBloc,
    setUp: () {
      when(getRecentGames()).thenThrow(Exception('network error'));
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    expect: () => [
      const HomeLoading(),
      isA<HomeFailure>().having(
        (state) => state.message,
        'message',
        isNot(contains('[DEBUG]')),
      ),
    ],
  );
}
