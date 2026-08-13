import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/round/domain/services/ranking_service.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';

import '../entities/game_history_item.dart';
import '../entities/game_history_source.dart';

class GameHistoryMapper {
  const GameHistoryMapper({RankingService? rankingService})
    : _rankingService = rankingService ?? const RankingService();

  final RankingService _rankingService;

  static const _monthNames = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  GameHistoryItem? fromCloudGame(Game game) {
    if (game.status != GameStatus.finished || game.finishedAt == null) {
      return null;
    }

    final ranking = _rankingService.buildRanking(
      players: game.players,
      scoresDelta: const {},
      includePositionDelta: false,
    );
    final winner = ranking.isNotEmpty ? ranking.first : null;

    return GameHistoryItem(
      id: game.id,
      source: GameHistorySource.cloud,
      finishedAt: game.finishedAt!,
      playerCount: game.playerCount,
      displayLabel: buildDisplayLabel(
        finishedAt: game.finishedAt!,
        playerDisplayNames: _sortedPlayerNames(game),
      ),
      winnerName: winner?.player.displayName,
      winnerScore: winner?.totalScore,
      cloudGameId: game.id,
    );
  }

  GameHistoryItem? fromLocalGame(Game game) {
    if (game.status != GameStatus.finished || game.finishedAt == null) {
      return null;
    }

    final ranking = _rankingService.buildRanking(
      players: game.players,
      scoresDelta: const {},
      includePositionDelta: false,
    );
    final winner = ranking.isNotEmpty ? ranking.first : null;

    return GameHistoryItem(
      id: game.id,
      source: GameHistorySource.local,
      finishedAt: game.finishedAt!,
      playerCount: game.playerCount,
      displayLabel: buildDisplayLabel(
        finishedAt: game.finishedAt!,
        playerDisplayNames: _sortedPlayerNames(game),
      ),
      winnerName: winner?.player.displayName,
      winnerScore: winner?.totalScore,
      cloudGameId: game.cloudGameId,
      isSyncPending: game.syncStatus == SyncStatus.pending,
    );
  }

  List<String> _sortedPlayerNames(Game game) {
    final sortedPlayers = List.of(game.players)
      ..sort((a, b) => a.seatOrder.compareTo(b.seatOrder));
    return sortedPlayers.map((player) => player.displayName).toList();
  }

  String buildDisplayLabel({
    required DateTime finishedAt,
    required List<String> playerDisplayNames,
  }) {
    final formattedDate = formatFinishedAt(finishedAt);
    final names = playerDisplayNames.join(', ');
    return '$formattedDate — $names';
  }

  String formatFinishedAt(DateTime finishedAt) {
    final day = finishedAt.day;
    final month = _monthNames[finishedAt.month - 1];
    final year = finishedAt.year;
    return '$day $month $year, ${_formatTime(finishedAt)}';
  }

  String formatRelativeFinishedAt(DateTime finishedAt, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final time = _formatTime(finishedAt);

    if (_isSameDate(finishedAt, current)) {
      return 'Hoy, $time';
    }

    final yesterday = DateTime(current.year, current.month, current.day - 1);
    if (_isSameDate(finishedAt, yesterday)) {
      return 'Ayer, $time';
    }

    final day = finishedAt.day;
    final month = _monthNames[finishedAt.month - 1];
    return '$day $month, $time';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
