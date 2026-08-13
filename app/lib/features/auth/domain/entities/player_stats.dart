import 'package:equatable/equatable.dart';

class PlayerStats extends Equatable {
  const PlayerStats({
    required this.totalGames,
    required this.wins,
    required this.winPercentage,
    required this.averagePosition,
    required this.bidAccuracyPercentage,
    required this.recordScore,
    required this.worstScore,
    required this.currentWinStreak,
    required this.bestWinStreak,
    this.mostFrequentPartner,
  });

  const PlayerStats.empty()
      : totalGames = 0,
        wins = 0,
        winPercentage = 0,
        averagePosition = 0,
        bidAccuracyPercentage = 0,
        recordScore = 0,
        worstScore = 0,
        currentWinStreak = 0,
        bestWinStreak = 0,
        mostFrequentPartner = null;

  final int totalGames;
  final int wins;
  final double winPercentage;
  final double averagePosition;
  final double bidAccuracyPercentage;
  final int recordScore;
  final int worstScore;
  final int currentWinStreak;
  final int bestWinStreak;
  final String? mostFrequentPartner;

  @override
  List<Object?> get props => [
        totalGames,
        wins,
        winPercentage,
        averagePosition,
        bidAccuracyPercentage,
        recordScore,
        worstScore,
        currentWinStreak,
        bestWinStreak,
        mostFrequentPartner,
      ];
}
