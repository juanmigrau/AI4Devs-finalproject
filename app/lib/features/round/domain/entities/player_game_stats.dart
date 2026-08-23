import 'package:equatable/equatable.dart';

class PlayerGameStats extends Equatable {
  const PlayerGameStats({
    required this.playerId,
    required this.displayName,
    required this.seatOrder,
    required this.totalBids,
    required this.totalTricks,
    required this.accuracyPercent,
    required this.currentStreak,
    required this.bestStreak,
    required this.bestRoundDelta,
    required this.worstRoundDelta,
    required this.averageScorePerRound,
  });

  final String playerId;
  final String displayName;
  final int seatOrder;
  final int totalBids;
  final int totalTricks;

  /// Null when there are no closed rounds (UI shows "—").
  final double? accuracyPercent;
  final int currentStreak;
  final int bestStreak;
  final int? bestRoundDelta;
  final int? worstRoundDelta;
  final double? averageScorePerRound;

  @override
  List<Object?> get props => [
        playerId,
        displayName,
        seatOrder,
        totalBids,
        totalTricks,
        accuracyPercent,
        currentStreak,
        bestStreak,
        bestRoundDelta,
        worstRoundDelta,
        averageScorePerRound,
      ];
}
