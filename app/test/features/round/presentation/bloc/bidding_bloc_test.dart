import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/round/domain/entities/bidding_context.dart';
import 'package:la_pocha/features/round/domain/entities/submit_bid_result.dart';
import 'package:la_pocha/features/round/domain/usecases/close_bidding_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/load_bidding_context_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/submit_bid_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/update_bid_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/bidding_bloc.dart';
import 'package:la_pocha/features/round/presentation/bloc/bidding_event.dart';
import 'package:la_pocha/features/round/presentation/bloc/bidding_state.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'bidding_bloc_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<LoadBiddingContextUseCase>(),
  MockSpec<SubmitBidUseCase>(),
  MockSpec<UpdateBidUseCase>(),
  MockSpec<CloseBiddingUseCase>(),
])
void main() {
  late MockLoadBiddingContextUseCase loadBiddingContext;
  late MockSubmitBidUseCase submitBid;
  late MockUpdateBidUseCase updateBid;
  late MockCloseBiddingUseCase closeBidding;

  const biddingOrder = ['p1', 'p2', 'p3', 'p0'];

  final players = [
    PlayerEmbed(
      id: 'p0',
      displayName: 'Dealer',
      isGuest: true,
      userId: null,
      seatOrder: 0,
      totalScore: 0,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 0,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p2',
      displayName: 'Bob',
      isGuest: true,
      userId: null,
      seatOrder: 2,
      totalScore: 0,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p3',
      displayName: 'Carla',
      isGuest: true,
      userId: null,
      seatOrder: 3,
      totalScore: 0,
      joinedAt: DateTime(2026),
    ),
  ];

  final game = Game(
    id: 'game-1',
    status: GameStatus.inProgress,
    playerCount: 4,
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

  Round round({Map<String, int> bids = const {}}) {
    return Round(
      id: 'round-1',
      gameId: 'game-1',
      roundNumber: 1,
      cardsInRound: 4,
      dealerPlayerId: 'p0',
      status: RoundStatus.bidding,
      bids: bids,
      createdAt: DateTime(2026),
    );
  }

  BiddingBloc buildBloc() => BiddingBloc(
        loadBiddingContext: loadBiddingContext,
        submitBid: submitBid,
        updateBid: updateBid,
        closeBidding: closeBidding,
      );

  setUp(() {
    loadBiddingContext = MockLoadBiddingContextUseCase();
    submitBid = MockSubmitBidUseCase();
    updateBid = MockUpdateBidUseCase();
    closeBidding = MockCloseBiddingUseCase();
  });

  blocTest<BiddingBloc, BiddingState>(
    'loads bidding context with indicators',
    build: buildBloc,
    setUp: () {
      when(
        loadBiddingContext(gameId: 'game-1', roundNumber: 1),
      ).thenAnswer(
        (_) async => BiddingContext(
          game: game,
          round: round(),
          biddingOrder: biddingOrder,
          currentPlayerId: 'p1',
        ),
      );
    },
    act: (bloc) => bloc.add(
      const BiddingStarted(gameId: 'game-1', roundNumber: 1),
    ),
    expect: () => [
      const BiddingLoading(),
      isA<BiddingLoaded>()
          .having((s) => s.currentPlayerId, 'currentPlayerId', 'p1')
          .having((s) => s.availableTricks, 'availableTricks', 4)
          .having((s) => s.canClose, 'canClose', false),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'updates draft bid and recalculates indicators',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 1}),
      biddingOrder: biddingOrder,
      currentPlayerId: 'p2',
      draftBid: 0,
      partialSum: 1,
      availableTricks: 3,
      canConfirmBid: true,
      canClose: false,
    ),
    act: (bloc) => bloc.add(const BidValueChanged(2)),
    expect: () => [
      isA<BiddingLoaded>()
          .having((s) => s.draftBid, 'draftBid', 2)
          .having((s) => s.canConfirmBid, 'canConfirmBid', true),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'blocks dealer forbidden bid confirmation',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 1, 'p2': 1, 'p3': 1}),
      biddingOrder: biddingOrder,
      currentPlayerId: 'p0',
      draftBid: 1,
      partialSum: 3,
      availableTricks: 1,
      forbiddenBid: 1,
      canConfirmBid: false,
      canClose: false,
    ),
    act: (bloc) => bloc.add(const BidConfirmed()),
    expect: () => [],
  );

  blocTest<BiddingBloc, BiddingState>(
    'confirms bid and advances turn',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(),
      biddingOrder: biddingOrder,
      currentPlayerId: 'p1',
      draftBid: 2,
      partialSum: 0,
      availableTricks: 4,
      canConfirmBid: true,
      canClose: false,
    ),
    setUp: () {
      when(
        submitBid(
          round: anyNamed('round'),
          biddingOrder: anyNamed('biddingOrder'),
          currentPlayerId: anyNamed('currentPlayerId'),
          bid: anyNamed('bid'),
        ),
      ).thenAnswer(
        (_) async => SubmitBidResult(
          round: round(bids: const {'p1': 2}),
          biddingOrder: biddingOrder,
          currentPlayerId: 'p2',
        ),
      );
    },
    act: (bloc) => bloc.add(const BidConfirmed()),
    expect: () => [
      isA<BiddingLoaded>().having((s) => s.isSubmitting, 'isSubmitting', true),
      isA<BiddingLoaded>()
          .having((s) => s.currentPlayerId, 'currentPlayerId', 'p2')
          .having((s) => s.availableTricks, 'availableTricks', 2),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'closes bidding and navigates to play',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 1, 'p2': 1, 'p3': 1, 'p0': 0}),
      biddingOrder: biddingOrder,
      currentPlayerId: null,
      draftBid: 0,
      partialSum: 3,
      availableTricks: 1,
      canConfirmBid: false,
      canClose: true,
    ),
    setUp: () {
      when(
        closeBidding(
          round: anyNamed('round'),
          playerIds: anyNamed('playerIds'),
        ),
      ).thenAnswer(
        (_) async => round(bids: const {'p1': 1, 'p2': 1, 'p3': 1, 'p0': 0})
            .copyWith(status: RoundStatus.playing),
      );
    },
    act: (bloc) => bloc.add(const CloseBiddingRequested()),
    expect: () => [
      isA<BiddingLoaded>().having((s) => s.isClosing, 'isClosing', true),
      isA<BiddingNavigateToPlay>()
          .having((s) => s.gameId, 'gameId', 'game-1')
          .having((s) => s.roundNumber, 'roundNumber', 1),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'activates edit mode with pre-filled draft bid',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 2, 'p2': 1}),
      biddingOrder: biddingOrder,
      currentPlayerId: 'p3',
      draftBid: 0,
      partialSum: 3,
      availableTricks: 1,
      canConfirmBid: true,
      canClose: false,
    ),
    act: (bloc) => bloc.add(const BidEditActivated('p1')),
    expect: () => [
      isA<BiddingLoaded>()
          .having((s) => s.editingPlayerId, 'editingPlayerId', 'p1')
          .having((s) => s.draftBid, 'draftBid', 2)
          .having((s) => s.availableTricks, 'availableTricks', 1)
          .having((s) => s.canClose, 'canClose', false),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'cancels edit without changing confirmed bids',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 2, 'p2': 1}),
      biddingOrder: biddingOrder,
      currentPlayerId: 'p3',
      draftBid: 3,
      partialSum: 4,
      availableTricks: 0,
      canConfirmBid: true,
      canClose: false,
      editingPlayerId: 'p1',
    ),
    act: (bloc) => bloc.add(const BidEditCancelled()),
    expect: () => [
      isA<BiddingLoaded>()
          .having((s) => s.editingPlayerId, 'editingPlayerId', null)
          .having((s) => s.draftBid, 'draftBid', 0)
          .having((s) => s.round.bids, 'bids', {'p1': 2, 'p2': 1})
          .having((s) => s.availableTricks, 'availableTricks', 1),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'switching edit row keeps first player confirmed bid',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 2, 'p2': 1}),
      biddingOrder: biddingOrder,
      currentPlayerId: 'p3',
      draftBid: 3,
      partialSum: 4,
      availableTricks: 0,
      canConfirmBid: true,
      canClose: false,
      editingPlayerId: 'p1',
    ),
    act: (bloc) => bloc.add(const BidEditActivated('p2')),
    expect: () => [
      isA<BiddingLoaded>()
          .having((s) => s.editingPlayerId, 'editingPlayerId', 'p2')
          .having((s) => s.draftBid, 'draftBid', 1)
          .having((s) => s.round.bids['p1'], 'p1 bid', 2),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'updates draft during edit and recalculates available tricks',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 2, 'p2': 1}),
      biddingOrder: biddingOrder,
      currentPlayerId: 'p3',
      draftBid: 2,
      partialSum: 3,
      availableTricks: 1,
      canConfirmBid: true,
      canClose: false,
      editingPlayerId: 'p1',
    ),
    act: (bloc) => bloc.add(const BidValueChanged(0)),
    expect: () => [
      isA<BiddingLoaded>()
          .having((s) => s.draftBid, 'draftBid', 0)
          .having((s) => s.availableTricks, 'availableTricks', 3)
          .having((s) => s.editingPlayerId, 'editingPlayerId', 'p1'),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'BidUpdated persists change and clears edit mode',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 2, 'p2': 1, 'p3': 1, 'p0': 0}),
      biddingOrder: biddingOrder,
      currentPlayerId: null,
      draftBid: 0,
      partialSum: 4,
      availableTricks: 0,
      forbiddenBid: 0,
      canConfirmBid: true,
      canClose: false,
      editingPlayerId: 'p1',
    ),
    setUp: () {
      when(
        updateBid(
          round: anyNamed('round'),
          playerId: anyNamed('playerId'),
          newBid: anyNamed('newBid'),
        ),
      ).thenAnswer(
        (_) async => round(bids: const {'p1': 0, 'p2': 1, 'p3': 1, 'p0': 0}),
      );
    },
    act: (bloc) => bloc.add(const BidUpdated(playerId: 'p1', newBid: 0)),
    expect: () => [
      isA<BiddingLoaded>().having((s) => s.isSubmitting, 'isSubmitting', true),
      isA<BiddingLoaded>()
          .having((s) => s.editingPlayerId, 'editingPlayerId', null)
          .having((s) => s.round.bids['p1'], 'p1 bid', 0)
          .having((s) => s.availableTricks, 'availableTricks', 2)
          .having((s) => s.canClose, 'canClose', true)
          .having((s) => s.forbiddenBid, 'forbiddenBid', 2),
    ],
  );

  blocTest<BiddingBloc, BiddingState>(
    'BidUpdated that breaks dealer restriction disables canClose',
    build: buildBloc,
    seed: () => BiddingLoaded(
      game: game,
      round: round(bids: const {'p1': 1, 'p2': 1, 'p3': 1, 'p0': 0}),
      biddingOrder: biddingOrder,
      currentPlayerId: null,
      draftBid: 2,
      partialSum: 4,
      availableTricks: 0,
      forbiddenBid: 1,
      canConfirmBid: true,
      canClose: false,
      editingPlayerId: 'p1',
    ),
    setUp: () {
      when(
        updateBid(
          round: anyNamed('round'),
          playerId: anyNamed('playerId'),
          newBid: anyNamed('newBid'),
        ),
      ).thenAnswer(
        (_) async => round(bids: const {'p1': 2, 'p2': 1, 'p3': 1, 'p0': 0}),
      );
    },
    act: (bloc) => bloc.add(const BidUpdated(playerId: 'p1', newBid: 2)),
    expect: () => [
      isA<BiddingLoaded>().having((s) => s.isSubmitting, 'isSubmitting', true),
      isA<BiddingLoaded>()
          .having((s) => s.round.bids['p1'], 'p1 bid', 2)
          .having((s) => s.canClose, 'canClose', false)
          .having((s) => s.forbiddenBid, 'forbiddenBid', 0),
    ],
  );
}
