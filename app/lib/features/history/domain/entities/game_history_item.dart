import 'package:equatable/equatable.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';

import 'game_history_source.dart';

class GameHistoryItem extends Equatable {
  const GameHistoryItem({
    required this.id,
    required this.source,
    required this.finishedAt,
    required this.playerCount,
    required this.displayLabel,
    this.winnerName,
    this.winnerScore,
    this.cloudGameId,
    this.syncStatus,
  });

  final String id;
  final GameHistorySource source;
  final DateTime finishedAt;
  final int playerCount;
  final String displayLabel;
  final String? winnerName;
  final int? winnerScore;
  final String? cloudGameId;
  final SyncStatus? syncStatus;

  bool get needsSyncRetry =>
      syncStatus == SyncStatus.pending || syncStatus == SyncStatus.failed;

  @override
  List<Object?> get props => [
        id,
        source,
        finishedAt,
        playerCount,
        displayLabel,
        winnerName,
        winnerScore,
        cloudGameId,
        syncStatus,
      ];
}
