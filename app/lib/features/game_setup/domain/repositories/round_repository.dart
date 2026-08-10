import '../entities/round.dart';

abstract class RoundRepository {
  Future<Round> insertRound(Round round);

  Future<Round?> getRoundByGameAndNumber(String gameId, int roundNumber);

  Future<List<Round>> getRoundsByGameId(String gameId);

  Future<Round> updateRound(Round round);
}
