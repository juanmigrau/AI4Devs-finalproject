import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/round/domain/entities/scorecard_row.dart';

class GetGameScorecardUseCase {
  GetGameScorecardUseCase(this._gameRepository, this._roundRepository);

  final GameRepository _gameRepository;
  final RoundRepository _roundRepository;

  Future<GameScorecard> call({required String gameId}) async {
    final game = await _gameRepository.getGameById(gameId);
    if (game == null) {
      throw StateError('Game not found: $gameId');
    }

    final rounds = await _roundRepository.getRoundsByGameId(gameId);
    final sortedRounds = List<Round>.from(rounds)
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    final players = List<PlayerEmbed>.from(game.players)
      ..sort((a, b) => a.seatOrder.compareTo(b.seatOrder));

    final closed = sortedRounds
        .where((round) => round.status == RoundStatus.closed)
        .toList();
    final current = sortedRounds
        .where((round) => round.status != RoundStatus.closed)
        .toList();
    final rowsSource = [
      ...closed,
      if (current.isNotEmpty) current.last,
    ];

    final cumulativeScores = {
      for (final player in players) player.id: 0,
    };

    final rows = <ScorecardRow>[];
    for (final round in rowsSource) {
      final isCurrent = round.status != RoundStatus.closed;
      final bids = <String, int?>{
        for (final player in players)
          player.id: round.bids.containsKey(player.id)
              ? round.bids[player.id]
              : null,
      };

      Map<String, int?> cumulative;
      if (isCurrent) {
        cumulative = {for (final player in players) player.id: null};
      } else {
        final scoresDelta = round.scoresDelta ?? const {};
        for (final player in players) {
          cumulativeScores[player.id] =
              (cumulativeScores[player.id] ?? 0) +
              (scoresDelta[player.id] ?? 0);
        }
        cumulative = {
          for (final player in players)
            player.id: cumulativeScores[player.id],
        };
      }

      rows.add(
        ScorecardRow(
          roundNumber: round.roundNumber,
          cardsInRound: round.cardsInRound,
          bids: bids,
          cumulative: cumulative,
          isCurrent: isCurrent,
        ),
      );
    }

    return GameScorecard(players: players, rows: rows);
  }
}
