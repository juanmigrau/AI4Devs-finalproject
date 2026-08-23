import 'dart:math' as math;

import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/round/domain/entities/game_curiosities.dart';
import 'package:la_pocha/features/round/domain/entities/game_stats.dart';
import 'package:la_pocha/features/round/domain/entities/player_game_stats.dart';

class GetGameStatsUseCase {
  GetGameStatsUseCase(this._gameRepository, this._roundRepository);

  final GameRepository _gameRepository;
  final RoundRepository _roundRepository;

  Future<GameStats> call({required String gameId}) async {
    final game = await _gameRepository.getGameById(gameId);
    if (game == null) {
      throw StateError('Game not found: $gameId');
    }

    final rounds = await _roundRepository.getRoundsByGameId(gameId);
    final closedRounds = List<Round>.from(rounds)
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    final closed = closedRounds
        .where((round) => round.status == RoundStatus.closed)
        .toList();

    final players = List<PlayerEmbed>.from(game.players)
      ..sort((a, b) => a.seatOrder.compareTo(b.seatOrder));

    final playerStats = players
        .map((player) => _computePlayerStats(player, closed))
        .toList()
      ..sort((a, b) {
        final aAcc = a.accuracyPercent ?? -1;
        final bAcc = b.accuracyPercent ?? -1;
        final cmp = bAcc.compareTo(aAcc);
        if (cmp != 0) return cmp;
        return a.seatOrder.compareTo(b.seatOrder);
      });

    final curiosities = closed.isEmpty
        ? const GameCuriosities.empty()
        : _computeCuriosities(players, closed);

    final progressSeries = _computeProgressSeries(players, closed);

    return GameStats(
      players: players,
      playerStats: playerStats,
      curiosities: curiosities,
      progressSeries: progressSeries,
      closedRoundCount: closed.length,
    );
  }

  PlayerGameStats _computePlayerStats(
    PlayerEmbed player,
    List<Round> closed,
  ) {
    if (closed.isEmpty) {
      return PlayerGameStats(
        playerId: player.id,
        displayName: player.displayName,
        seatOrder: player.seatOrder,
        totalBids: 0,
        totalTricks: 0,
        accuracyPercent: null,
        currentStreak: 0,
        bestStreak: 0,
        bestRoundDelta: null,
        worstRoundDelta: null,
        averageScorePerRound: null,
      );
    }

    var totalBids = 0;
    var totalTricks = 0;
    var accurateCount = 0;
    var scoreSum = 0;
    int? bestDelta;
    int? worstDelta;

    for (final round in closed) {
      totalBids += round.bids[player.id] ?? 0;
      totalTricks += round.tricks?[player.id] ?? 0;
      if (_isAccurate(round, player.id)) {
        accurateCount++;
      }
      final delta = round.scoresDelta?[player.id] ?? 0;
      scoreSum += delta;
      bestDelta = bestDelta == null ? delta : math.max(bestDelta, delta);
      worstDelta = worstDelta == null ? delta : math.min(worstDelta, delta);
    }

    var currentStreak = 0;
    for (final round in closed.reversed) {
      if (_isAccurate(round, player.id)) {
        currentStreak++;
      } else {
        break;
      }
    }

    var bestStreak = 0;
    var streak = 0;
    for (final round in closed) {
      if (_isAccurate(round, player.id)) {
        streak++;
        bestStreak = math.max(bestStreak, streak);
      } else {
        streak = 0;
      }
    }

    return PlayerGameStats(
      playerId: player.id,
      displayName: player.displayName,
      seatOrder: player.seatOrder,
      totalBids: totalBids,
      totalTricks: totalTricks,
      accuracyPercent: (accurateCount / closed.length) * 100,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      bestRoundDelta: bestDelta,
      worstRoundDelta: worstDelta,
      averageScorePerRound: scoreSum / closed.length,
    );
  }

  GameCuriosities _computeCuriosities(
    List<PlayerEmbed> players,
    List<Round> closed,
  ) {
    int? mostEqualRoundNumber;
    var smallestSpread = double.infinity;
    for (final round in closed) {
      final deltas = players
          .map((p) => round.scoresDelta?[p.id] ?? 0)
          .toList();
      final spread = (deltas.reduce(math.max) - deltas.reduce(math.min))
          .toDouble();
      if (spread < smallestSpread) {
        smallestSpread = spread;
        mostEqualRoundNumber = round.roundNumber;
      }
    }

    final totalCards = closed.fold<int>(0, (sum, r) => sum + r.cardsInRound);
    String? riskiestId;
    String? riskiestName;
    String? conservativeId;
    String? conservativeName;
    var maxRatio = -1.0;
    var minRatio = double.infinity;

    if (totalCards > 0) {
      for (final player in players) {
        final totalBids = closed.fold<int>(
          0,
          (sum, r) => sum + (r.bids[player.id] ?? 0),
        );
        final ratio = totalBids / totalCards;
        if (ratio > maxRatio) {
          maxRatio = ratio;
          riskiestId = player.id;
          riskiestName = player.displayName;
        }
        if (ratio < minRatio) {
          minRatio = ratio;
          conservativeId = player.id;
          conservativeName = player.displayName;
        }
      }
    }

    return GameCuriosities(
      mostEqualRoundNumber: mostEqualRoundNumber,
      riskiestPlayerId: riskiestId,
      riskiestPlayerName: riskiestName,
      mostConservativePlayerId: conservativeId,
      mostConservativePlayerName: conservativeName,
    );
  }

  List<PlayerProgressSeries> _computeProgressSeries(
    List<PlayerEmbed> players,
    List<Round> closed,
  ) {
    final cumulative = {for (final p in players) p.id: 0};
    final pointsByPlayer = {
      for (final p in players) p.id: <PlayerProgressPoint>[],
    };

    for (final round in closed) {
      final scoresDelta = round.scoresDelta ?? const {};
      for (final player in players) {
        cumulative[player.id] =
            (cumulative[player.id] ?? 0) + (scoresDelta[player.id] ?? 0);
      }

      final ranked = List<MapEntry<String, int>>.from(cumulative.entries)
        ..sort((a, b) => b.value.compareTo(a.value));
      final ranks = _assignRanks(ranked);

      for (final player in players) {
        pointsByPlayer[player.id]!.add(
          PlayerProgressPoint(
            roundNumber: round.roundNumber,
            cumulativeScore: cumulative[player.id]!,
            position: ranks[player.id]!,
          ),
        );
      }
    }

    return players
        .map(
          (player) => PlayerProgressSeries(
            playerId: player.id,
            displayName: player.displayName,
            seatOrder: player.seatOrder,
            points: pointsByPlayer[player.id]!,
          ),
        )
        .toList();
  }

  /// Same tie logic as [RankingService]: equal scores share the same rank.
  Map<String, int> _assignRanks(List<MapEntry<String, int>> idAndScores) {
    final ranks = <String, int>{};
    var rank = 1;
    for (var i = 0; i < idAndScores.length; i++) {
      if (i > 0 && idAndScores[i].value < idAndScores[i - 1].value) {
        rank = i + 1;
      }
      ranks[idAndScores[i].key] = rank;
    }
    return ranks;
  }

  bool _isAccurate(Round round, String playerId) {
    final bid = round.bids[playerId];
    final tricks = round.tricks?[playerId];
    if (bid == null || tricks == null) return false;
    return bid == tricks;
  }
}
