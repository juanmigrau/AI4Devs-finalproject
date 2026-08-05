import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/round/domain/usecases/revert_round_to_bidding_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'revert_round_to_bidding_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RoundRepository>()])
void main() {
  late MockRoundRepository roundRepository;
  late RevertRoundToBiddingUseCase useCase;

  Round baseRound({
    RoundStatus status = RoundStatus.playing,
    Map<String, int> bids = const {'p0': 0, 'p1': 2},
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
    useCase = RevertRoundToBiddingUseCase(roundRepository);
  });

  test('changes status from playing to bidding and preserves bids', () async {
    final round = baseRound();
    when(roundRepository.getRoundByGameAndNumber('game-1', 1))
        .thenAnswer((_) async => round);
    when(roundRepository.updateRound(any)).thenAnswer(
      (invocation) async => invocation.positionalArguments[0] as Round,
    );

    final result = await useCase(gameId: 'game-1', roundNumber: 1);

    expect(result.status, RoundStatus.bidding);
    expect(result.bids, equals(const {'p0': 0, 'p1': 2}));
    expect(result.dealerPlayerId, 'p0');
    expect(result.cardsInRound, 4);
    expect(result.roundNumber, 1);

    final captured = verify(roundRepository.updateRound(captureAny))
        .captured
        .single as Round;
    expect(captured.status, RoundStatus.bidding);
    expect(captured.bids, equals(const {'p0': 0, 'p1': 2}));
    expect(captured.dealerPlayerId, 'p0');
  });

  test('does nothing when round is already bidding', () async {
    final round = baseRound(status: RoundStatus.bidding);
    when(roundRepository.getRoundByGameAndNumber('game-1', 1))
        .thenAnswer((_) async => round);

    final result = await useCase(gameId: 'game-1', roundNumber: 1);

    expect(result.status, RoundStatus.bidding);
    expect(result.bids, equals(const {'p0': 0, 'p1': 2}));
    verifyNever(roundRepository.updateRound(any));
  });

  test('throws when round is not found', () async {
    when(roundRepository.getRoundByGameAndNumber('game-1', 1))
        .thenAnswer((_) async => null);

    expect(
      () => useCase(gameId: 'game-1', roundNumber: 1),
      throwsStateError,
    );
    verifyNever(roundRepository.updateRound(any));
  });

  test('throws when round is closed', () async {
    final round = baseRound(status: RoundStatus.closed);
    when(roundRepository.getRoundByGameAndNumber('game-1', 1))
        .thenAnswer((_) async => round);

    expect(
      () => useCase(gameId: 'game-1', roundNumber: 1),
      throwsStateError,
    );
    verifyNever(roundRepository.updateRound(any));
  });
}
