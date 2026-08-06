import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/round/domain/entities/round_play_state.dart';
import 'package:la_pocha/features/round/domain/usecases/close_round_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/get_round_play_state_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/scoring_bloc.dart';
import 'package:la_pocha/features/round/presentation/bloc/scoring_event.dart';
import 'package:la_pocha/features/round/presentation/bloc/scoring_state.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'scoring_bloc_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetRoundPlayStateUseCase>(),
  MockSpec<CloseRoundUseCase>(),
])
void main() {
  late MockGetRoundPlayStateUseCase getRoundPlayState;
  late MockCloseRoundUseCase closeRound;

  // Dealer p1 → scoringOrder = [p2, p1]
  const scoringOrder = ['p2', 'p1'];

  final players = [
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 0,
      totalScore: 10,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p2',
      displayName: 'Bob',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 5,
      joinedAt: DateTime(2026),
    ),
  ];

  final game = Game(
    id: 'game-1',
    status: GameStatus.inProgress,
    playerCount: 2,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [
      RoundDefinition(roundNumber: 1, cardsPerPlayer: 4),
    ],
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
    dealerPlayerId: 'p1',
    status: RoundStatus.playing,
    bids: const {'p1': 2, 'p2': 2},
    createdAt: DateTime(2026),
  );

  final playState = RoundPlayState(
    game: game,
    round: round,
    players: players,
    bidSum: 4,
    restrictionMet: false,
  );

  ScoringBloc buildBloc() {
    return ScoringBloc(
      getRoundPlayState: getRoundPlayState,
      closeRound: closeRound,
    );
  }

  ScoringLoaded loaded({
    Map<String, int> confirmedTricks = const {},
    String? currentPlayerId = 'p2',
    int draftTrick = 2,
    int tricksSum = 0,
    int remainingTricks = 4,
    bool canConfirmTrick = true,
    bool canConfirm = false,
    bool canAddMore = true,
    String? editingPlayerId,
  }) {
    return ScoringLoaded(
      game: game,
      round: round,
      scoringOrder: scoringOrder,
      confirmedTricks: confirmedTricks,
      currentPlayerId: currentPlayerId,
      draftTrick: draftTrick,
      tricksSum: tricksSum,
      remainingTricks: remainingTricks,
      canConfirmTrick: canConfirmTrick,
      canConfirm: canConfirm,
      canAddMore: canAddMore,
      editingPlayerId: editingPlayerId,
    );
  }

  setUp(() {
    getRoundPlayState = MockGetRoundPlayStateUseCase();
    closeRound = MockCloseRoundUseCase();
  });

  blocTest<ScoringBloc, ScoringState>(
    'loads scoring with draftTrick equal to current player bid',
    build: buildBloc,
    setUp: () {
      when(
        getRoundPlayState(
          gameId: anyNamed('gameId'),
          roundNumber: anyNamed('roundNumber'),
        ),
      ).thenAnswer((_) async => playState);
    },
    act: (bloc) => bloc.add(
      const ScoringStarted(gameId: 'game-1', roundNumber: 1),
    ),
    expect: () => [
      const ScoringLoading(),
      isA<ScoringLoaded>()
          .having((s) => s.scoringOrder, 'scoringOrder', scoringOrder)
          .having((s) => s.currentPlayerId, 'currentPlayerId', 'p2')
          .having((s) => s.draftTrick, 'draftTrick', 2)
          .having((s) => s.confirmedTricks, 'confirmedTricks', <String, int>{})
          .having((s) => s.remainingTricks, 'remainingTricks', 4)
          .having((s) => s.canAddMore, 'canAddMore', true)
          .having((s) => s.canConfirm, 'canConfirm', false),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'updates draft trick value',
    build: buildBloc,
    seed: loaded,
    act: (bloc) => bloc.add(const TrickValueChanged(3)),
    expect: () => [
      isA<ScoringLoaded>()
          .having((s) => s.draftTrick, 'draftTrick', 3)
          .having((s) => s.canConfirmTrick, 'canConfirmTrick', true),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'confirms tricks and advances to next player with bid as draft',
    build: buildBloc,
    seed: loaded,
    act: (bloc) => bloc.add(const TricksConfirmed()),
    expect: () => [
      isA<ScoringLoaded>()
          .having(
            (s) => s.confirmedTricks,
            'confirmedTricks',
            {'p2': 2},
          )
          .having((s) => s.currentPlayerId, 'currentPlayerId', 'p1')
          .having((s) => s.draftTrick, 'draftTrick', 2)
          .having((s) => s.remainingTricks, 'remainingTricks', 2)
          .having((s) => s.canAddMore, 'canAddMore', false)
          .having((s) => s.canConfirm, 'canConfirm', false),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'enables confirm when all tricks match cards in round',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 2},
      currentPlayerId: 'p1',
      draftTrick: 2,
      tricksSum: 2,
      remainingTricks: 2,
    ),
    act: (bloc) => bloc.add(const TricksConfirmed()),
    expect: () => [
      isA<ScoringLoaded>()
          .having(
            (s) => s.confirmedTricks,
            'confirmedTricks',
            {'p2': 2, 'p1': 2},
          )
          .having((s) => s.currentPlayerId, 'currentPlayerId', null)
          .having((s) => s.remainingTricks, 'remainingTricks', 0)
          .having((s) => s.canConfirm, 'canConfirm', true),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'activates edit with current confirmed value as draft',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 2, 'p1': 2},
      currentPlayerId: null,
      draftTrick: 0,
      tricksSum: 4,
      remainingTricks: 0,
      canConfirm: true,
    ),
    act: (bloc) => bloc.add(const TricksEditActivated('p2')),
    expect: () => [
      isA<ScoringLoaded>()
          .having((s) => s.editingPlayerId, 'editingPlayerId', 'p2')
          .having((s) => s.draftTrick, 'draftTrick', 2)
          .having((s) => s.canConfirm, 'canConfirm', false)
          .having((s) => s.remainingTricks, 'remainingTricks', 0),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'cancels edit without changing confirmed tricks',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 2, 'p1': 2},
      currentPlayerId: null,
      draftTrick: 3,
      tricksSum: 5,
      remainingTricks: -1,
      canConfirm: false,
      editingPlayerId: 'p2',
    ),
    act: (bloc) => bloc.add(const TricksEditCancelled()),
    expect: () => [
      isA<ScoringLoaded>()
          .having((s) => s.editingPlayerId, 'editingPlayerId', null)
          .having(
            (s) => s.confirmedTricks,
            'confirmedTricks',
            {'p2': 2, 'p1': 2},
          )
          .having((s) => s.remainingTricks, 'remainingTricks', 0)
          .having((s) => s.canConfirm, 'canConfirm', true),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'updates confirmed tricks on edit confirm and recalculates remaining',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 2, 'p1': 2},
      currentPlayerId: null,
      draftTrick: 1,
      tricksSum: 3,
      remainingTricks: 1,
      canConfirm: false,
      editingPlayerId: 'p2',
    ),
    act: (bloc) =>
        bloc.add(const TricksUpdated(playerId: 'p2', newTricks: 1)),
    expect: () => [
      isA<ScoringLoaded>()
          .having(
            (s) => s.confirmedTricks,
            'confirmedTricks',
            {'p2': 1, 'p1': 2},
          )
          .having((s) => s.editingPlayerId, 'editingPlayerId', null)
          .having((s) => s.remainingTricks, 'remainingTricks', 1)
          .having((s) => s.canConfirm, 'canConfirm', false),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'closes round and navigates to result',
    build: buildBloc,
    setUp: () {
      when(
        closeRound(
          gameId: anyNamed('gameId'),
          round: anyNamed('round'),
          players: anyNamed('players'),
          tricks: anyNamed('tricks'),
        ),
      ).thenAnswer((_) async => round.copyWith(status: RoundStatus.closed));
    },
    seed: () => loaded(
      confirmedTricks: const {'p2': 2, 'p1': 2},
      currentPlayerId: null,
      draftTrick: 0,
      tricksSum: 4,
      remainingTricks: 0,
      canConfirm: true,
    ),
    act: (bloc) => bloc.add(const CloseRoundRequested()),
    expect: () => [
      isA<ScoringLoaded>().having((s) => s.isClosing, 'isClosing', true),
      isA<ScoringNavigateToResult>()
          .having((s) => s.gameId, 'gameId', 'game-1')
          .having((s) => s.roundNumber, 'roundNumber', 1),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'does not close when tricks sum is invalid',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 2, 'p1': 1},
      currentPlayerId: null,
      draftTrick: 0,
      tricksSum: 3,
      remainingTricks: 1,
      canConfirm: false,
    ),
    act: (bloc) => bloc.add(const CloseRoundRequested()),
    expect: () => [],
    verify: (_) {
      verifyNever(
        closeRound(
          gameId: anyNamed('gameId'),
          round: anyNamed('round'),
          players: anyNamed('players'),
          tricks: anyNamed('tricks'),
        ),
      );
    },
  );

  blocTest<ScoringBloc, ScoringState>(
    'canAddMore is false when confirmed plus draft equals cardsInRound',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 3},
      currentPlayerId: 'p1',
      draftTrick: 0,
      tricksSum: 3,
      remainingTricks: 1,
      canAddMore: true,
    ),
    act: (bloc) => bloc.add(const TrickValueChanged(1)),
    expect: () => [
      isA<ScoringLoaded>()
          .having((s) => s.draftTrick, 'draftTrick', 1)
          .having((s) => s.canAddMore, 'canAddMore', false)
          .having((s) => s.remainingTricks, 'remainingTricks', 1),
    ],
  );

  blocTest<ScoringBloc, ScoringState>(
    'rejects draft increase when canAddMore is false',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 3},
      currentPlayerId: 'p1',
      draftTrick: 1,
      tricksSum: 3,
      remainingTricks: 1,
      canAddMore: false,
    ),
    act: (bloc) => bloc.add(const TrickValueChanged(2)),
    expect: () => [],
  );

  blocTest<ScoringBloc, ScoringState>(
    'canAddMore is false when editing would exceed cardsInRound on increment',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 2, 'p1': 2},
      currentPlayerId: null,
      draftTrick: 2,
      tricksSum: 4,
      remainingTricks: 0,
      canConfirm: false,
      canAddMore: false,
      editingPlayerId: 'p2',
    ),
    act: (bloc) => bloc.add(const TrickValueChanged(3)),
    expect: () => [],
  );

  blocTest<ScoringBloc, ScoringState>(
    'allows decreasing draft while at cardsInRound limit',
    build: buildBloc,
    seed: () => loaded(
      confirmedTricks: const {'p2': 2, 'p1': 2},
      currentPlayerId: null,
      draftTrick: 2,
      tricksSum: 4,
      remainingTricks: 0,
      canConfirm: false,
      canAddMore: false,
      editingPlayerId: 'p2',
    ),
    act: (bloc) => bloc.add(const TrickValueChanged(1)),
    expect: () => [
      isA<ScoringLoaded>()
          .having((s) => s.draftTrick, 'draftTrick', 1)
          .having((s) => s.remainingTricks, 'remainingTricks', 1)
          .having((s) => s.canAddMore, 'canAddMore', true),
    ],
  );
}
