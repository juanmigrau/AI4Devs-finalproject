import 'package:equatable/equatable.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/game_curiosities.dart';
import 'package:la_pocha/features/round/domain/entities/player_game_stats.dart';

class PlayerProgressPoint extends Equatable {
  const PlayerProgressPoint({
    required this.roundNumber,
    required this.cumulativeScore,
    required this.position,
  });

  final int roundNumber;
  final int cumulativeScore;
  final int position;

  @override
  List<Object?> get props => [roundNumber, cumulativeScore, position];
}

class PlayerProgressSeries extends Equatable {
  const PlayerProgressSeries({
    required this.playerId,
    required this.displayName,
    required this.seatOrder,
    required this.points,
  });

  final String playerId;
  final String displayName;
  final int seatOrder;
  final List<PlayerProgressPoint> points;

  @override
  List<Object?> get props => [playerId, displayName, seatOrder, points];
}

class GameStats extends Equatable {
  const GameStats({
    required this.players,
    required this.playerStats,
    required this.curiosities,
    required this.progressSeries,
    required this.closedRoundCount,
  });

  final List<PlayerEmbed> players;

  /// Sorted by accuracy descending (skill ranking).
  final List<PlayerGameStats> playerStats;
  final GameCuriosities curiosities;
  final List<PlayerProgressSeries> progressSeries;
  final int closedRoundCount;

  @override
  List<Object?> get props => [
        players,
        playerStats,
        curiosities,
        progressSeries,
        closedRoundCount,
      ];
}
