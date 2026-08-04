import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/round/domain/usecases/update_bid_usecase.dart';
import 'package:mockito/mockito.dart';

import 'correct_bids_usecase_test.mocks.dart';

void main() {
  late MockRoundRepository roundRepository;
  late UpdateBidUseCase useCase;

  Round baseRound({
    Map<String, int> bids = const {'p1': 1, 'p2': 1, 'p3': 1, 'p0': 0},
    RoundStatus status = RoundStatus.bidding,
  }) {
    return Round(
      id: 'round-1',
      gameId: 'game-1',
      roundNumber: 1,
      cardsInRound: 4,
      dealerPlayerId: 'p0',
      status: status,
      bids: bids,
      createdAt: DateTime(2026),
    );
  }

  setUp(() {
    roundRepository = MockRoundRepository();
    useCase = UpdateBidUseCase(roundRepository);
    when(roundRepository.updateRound(any)).thenAnswer(
      (invocation) async => invocation.positionalArguments[0] as Round,
    );
  });

  test('persists updated bid for a player who already bid', () async {
    final round = baseRound();

    final result = await useCase(
      round: round,
      playerId: 'p1',
      newBid: 2,
    );

    expect(result.bids, {'p1': 2, 'p2': 1, 'p3': 1, 'p0': 0});
    final captured = verify(roundRepository.updateRound(captureAny))
        .captured
        .single as Round;
    expect(captured.bids['p1'], 2);
  });

  test('allows updating a non-dealer bid mid-sequence', () async {
    final round = baseRound(bids: const {'p1': 2, 'p2': 1});

    final result = await useCase(
      round: round,
      playerId: 'p1',
      newBid: 0,
    );

    expect(result.bids, {'p1': 0, 'p2': 1});
    verify(roundRepository.updateRound(any)).called(1);
  });

  test('blocks dealer from updating to forbidden value', () async {
    final round = baseRound(
      bids: const {'p1': 1, 'p2': 1, 'p3': 1, 'p0': 0},
    );

    expect(
      () => useCase(round: round, playerId: 'p0', newBid: 1),
      throwsStateError,
    );
    verifyNever(roundRepository.updateRound(any));
  });

  test('allows dealer to update to a non-forbidden value', () async {
    final round = baseRound(
      bids: const {'p1': 1, 'p2': 1, 'p3': 1, 'p0': 0},
    );

    final result = await useCase(
      round: round,
      playerId: 'p0',
      newBid: 2,
    );

    expect(result.bids['p0'], 2);
    verify(roundRepository.updateRound(any)).called(1);
  });

  test(
    'allows dealer update to any bid when others already exceed cardsInRound',
    () async {
      final round = Round(
        id: 'round-1',
        gameId: 'game-1',
        roundNumber: 1,
        cardsInRound: 1,
        dealerPlayerId: 'p0',
        status: RoundStatus.bidding,
        bids: const {'p1': 1, 'p2': 1, 'p0': 0},
        createdAt: DateTime(2026),
      );
      when(roundRepository.updateRound(any)).thenAnswer(
        (invocation) async => invocation.positionalArguments[0] as Round,
      );

      final result = await useCase(round: round, playerId: 'p0', newBid: 0);

      expect(result.bids['p0'], 0);
      verify(roundRepository.updateRound(any)).called(1);
    },
  );

  test('throws ArgumentError when bid is out of range', () async {
    expect(
      () => useCase(round: baseRound(), playerId: 'p1', newBid: 5),
      throwsArgumentError,
    );
    verifyNever(roundRepository.updateRound(any));
  });

  test('throws ArgumentError when bid is negative', () async {
    expect(
      () => useCase(round: baseRound(), playerId: 'p1', newBid: -1),
      throwsArgumentError,
    );
    verifyNever(roundRepository.updateRound(any));
  });

  test('throws StateError when player has not submitted a bid', () async {
    final round = baseRound(bids: const {'p1': 1});

    expect(
      () => useCase(round: round, playerId: 'p2', newBid: 1),
      throwsStateError,
    );
    verifyNever(roundRepository.updateRound(any));
  });

  test('throws StateError when round is not in bidding status', () async {
    final round = baseRound(status: RoundStatus.playing);

    expect(
      () => useCase(round: round, playerId: 'p1', newBid: 2),
      throwsStateError,
    );
    verifyNever(roundRepository.updateRound(any));
  });
}
