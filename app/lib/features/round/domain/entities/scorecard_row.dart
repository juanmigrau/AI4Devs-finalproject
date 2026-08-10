import 'package:equatable/equatable.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';

class ScorecardRow extends Equatable {
  const ScorecardRow({
    required this.roundNumber,
    required this.cardsInRound,
    required this.bids,
    required this.cumulative,
    required this.isCurrent,
  });

  final int roundNumber;
  final int cardsInRound;
  final Map<String, int?> bids;
  final Map<String, int?> cumulative;
  final bool isCurrent;

  @override
  List<Object?> get props => [
        roundNumber,
        cardsInRound,
        bids,
        cumulative,
        isCurrent,
      ];
}

class GameScorecard extends Equatable {
  const GameScorecard({
    required this.players,
    required this.rows,
  });

  final List<PlayerEmbed> players;
  final List<ScorecardRow> rows;

  @override
  List<Object?> get props => [players, rows];
}
