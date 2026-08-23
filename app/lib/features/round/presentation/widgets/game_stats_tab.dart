import 'package:flutter/material.dart';
import 'package:la_pocha/features/round/domain/entities/game_stats.dart';
import 'package:la_pocha/features/round/presentation/widgets/game_curiosities_section.dart';
import 'package:la_pocha/features/round/presentation/widgets/player_stats_card.dart';

class GameStatsTab extends StatelessWidget {
  const GameStatsTab({super.key, required this.stats});

  final GameStats stats;

  static const String emptyMessage =
      'Juega más rondas para ver las estadísticas';

  @override
  Widget build(BuildContext context) {
    if (stats.closedRoundCount < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Text(
            'Clasificación por acierto',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        for (var i = 0; i < stats.playerStats.length; i++)
          PlayerStatsCard(
            stats: stats.playerStats[i],
            rank: i + 1,
          ),
        GameCuriositiesSection(curiosities: stats.curiosities),
      ],
    );
  }
}
