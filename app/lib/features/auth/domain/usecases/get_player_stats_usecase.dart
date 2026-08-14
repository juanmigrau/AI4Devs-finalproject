import 'package:la_pocha/features/auth/domain/entities/player_stats.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/history/domain/entities/game_detail.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_detail_usecase.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_history_usecase.dart';

class GetPlayerStatsUseCase {
  const GetPlayerStatsUseCase({
    required this._getGameHistory,
    required this._getGameDetail,
  });

  final GetGameHistoryUseCase _getGameHistory;
  final GetGameDetailUseCase _getGameDetail;

  Future<PlayerStats> call({required String userId}) async {
    final history = await _getGameHistory();
    if (history.items.isEmpty) {
      return const PlayerStats.empty();
    }

    final details = <GameDetail>[];
    for (final item in history.items) {
      try {
        final detail = await _getGameDetail(
          gameId: item.id,
          source: item.source,
        );
        if (_isUserGame(detail.game, userId)) {
          details.add(detail);
        }
      } catch (_) {
        // Skip games whose detail cannot be loaded.
      }
    }

    if (details.isEmpty) {
      return const PlayerStats.empty();
    }

    return _compute(userId: userId, details: details);
  }

  PlayerStats _compute({
    required String userId,
    required List<GameDetail> details,
  }) {
    final sortedDesc = List<GameDetail>.from(details)
      ..sort(
        (a, b) => (b.game.finishedAt ?? b.game.updatedAt).compareTo(
          a.game.finishedAt ?? a.game.updatedAt,
        ),
      );

    var wins = 0;
    var positionSum = 0.0;
    var recordScore = 0;
    var worstScore = 0;
    var scoresInitialized = false;
    var accurateBids = 0;
    var closedRoundsCount = 0;
    final partnerCounts = <String, _PartnerCount>{};

    for (final detail in sortedDesc) {
      final self = _findSelf(detail.game.players, userId)!;
      final rank = _rankFor(detail, userId);
      final won = rank == 1;
      if (won) {
        wins++;
      }
      positionSum += rank;

      final score = self.totalScore;
      if (!scoresInitialized) {
        recordScore = score;
        worstScore = score;
        scoresInitialized = true;
      } else {
        if (score > recordScore) {
          recordScore = score;
        }
        if (score < worstScore) {
          worstScore = score;
        }
      }

      for (final summary in detail.roundSummaries) {
        closedRoundsCount++;
        if (_isAccurateBid(summary.round, self.id)) {
          accurateBids++;
        }
      }

      for (final player in detail.game.players) {
        if (player.userId == userId) {
          continue;
        }
        final key = player.userId ?? 'guest:${player.displayName}';
        final existing = partnerCounts[key];
        if (existing == null) {
          partnerCounts[key] = _PartnerCount(player.displayName, 1);
        } else {
          partnerCounts[key] = _PartnerCount(
            existing.displayName,
            existing.count + 1,
          );
        }
      }
    }

    final totalGames = sortedDesc.length;
    final winPercentage = totalGames == 0 ? 0.0 : (wins / totalGames) * 100;
    final averagePosition = totalGames == 0 ? 0.0 : positionSum / totalGames;
    final bidAccuracyPercentage = closedRoundsCount == 0
        ? 0.0
        : (accurateBids / closedRoundsCount) * 100;

    String? mostFrequentPartner;
    var maxPartnerCount = 0;
    for (final entry in partnerCounts.values) {
      if (entry.count > maxPartnerCount) {
        maxPartnerCount = entry.count;
        mostFrequentPartner = entry.displayName;
      }
    }

    final winsByDateDesc = sortedDesc
        .map((d) => _rankFor(d, userId) == 1)
        .toList();
    final currentWinStreak = _currentStreak(winsByDateDesc);

    final sortedAsc = List<GameDetail>.from(sortedDesc).reversed.toList();
    final winsByDateAsc = sortedAsc
        .map((d) => _rankFor(d, userId) == 1)
        .toList();
    final bestWinStreak = _bestStreak(winsByDateAsc);

    return PlayerStats(
      totalGames: totalGames,
      wins: wins,
      winPercentage: winPercentage,
      averagePosition: averagePosition,
      bidAccuracyPercentage: bidAccuracyPercentage,
      recordScore: recordScore,
      worstScore: worstScore,
      currentWinStreak: currentWinStreak,
      bestWinStreak: bestWinStreak,
      mostFrequentPartner: mostFrequentPartner,
    );
  }

  /// A game counts toward stats only when the authenticated [userId] is in
  /// `players[].userId`. Display name and [Game.syncStatus] are never used
  /// to infer identity (local guest games stay out until claimed by userId).
  bool _isUserGame(Game game, String userId) {
    return game.players.any((player) => player.userId == userId);
  }

  PlayerEmbed? _findSelf(List<PlayerEmbed> players, String userId) {
    for (final player in players) {
      if (player.userId == userId) {
        return player;
      }
    }
    return null;
  }

  int _rankFor(GameDetail detail, String userId) {
    for (final entry in detail.finalRanking) {
      if (entry.player.userId == userId) {
        return entry.rank;
      }
    }
    final self = _findSelf(detail.game.players, userId)!;
    final sorted = List<PlayerEmbed>.from(detail.game.players)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    var rank = 1;
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].totalScore < sorted[i - 1].totalScore) {
        rank = i + 1;
      }
      if (sorted[i].id == self.id) {
        return rank;
      }
    }
    return sorted.length;
  }

  bool _isAccurateBid(Round round, String playerId) {
    final bid = round.bids[playerId];
    final tricks = round.tricks?[playerId];
    if (bid == null || tricks == null) {
      return false;
    }
    return bid == tricks;
  }

  int _currentStreak(List<bool> winsNewestFirst) {
    var streak = 0;
    for (final won in winsNewestFirst) {
      if (!won) {
        break;
      }
      streak++;
    }
    return streak;
  }

  int _bestStreak(List<bool> winsOldestFirst) {
    var best = 0;
    var current = 0;
    for (final won in winsOldestFirst) {
      if (won) {
        current++;
        if (current > best) {
          best = current;
        }
      } else {
        current = 0;
      }
    }
    return best;
  }
}

class _PartnerCount {
  const _PartnerCount(this.displayName, this.count);

  final String displayName;
  final int count;
}
