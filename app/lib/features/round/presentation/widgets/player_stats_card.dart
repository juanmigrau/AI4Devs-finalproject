import 'package:flutter/material.dart';
import 'package:la_pocha/core/utils/player_colors.dart';
import 'package:la_pocha/features/round/domain/entities/player_game_stats.dart';

class PlayerStatsCard extends StatelessWidget {
  const PlayerStatsCard({
    super.key,
    required this.stats,
    required this.rank,
  });

  final PlayerGameStats stats;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = playerAvatarColorForIndex(stats.seatOrder);
    final accuracy = stats.accuracyPercent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text(
                    '#$rank',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stats.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  accuracy == null
                      ? '—'
                      : '${accuracy.toStringAsFixed(0)}% acierto',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _StatChip(
                  label: 'Bazas',
                  value: '${stats.totalBids} / ${stats.totalTricks}',
                ),
                _StatChip(
                  label: 'Racha actual',
                  value: '${stats.currentStreak}',
                ),
                _StatChip(
                  label: 'Mejor racha',
                  value: '${stats.bestStreak}',
                ),
                _StatChip(
                  label: 'Mejor ronda',
                  value: _deltaLabel(stats.bestRoundDelta),
                ),
                _StatChip(
                  label: 'Peor ronda',
                  value: _deltaLabel(stats.worstRoundDelta),
                ),
                _StatChip(
                  label: 'Media / ronda',
                  value: stats.averageScorePerRound == null
                      ? '—'
                      : stats.averageScorePerRound!.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _deltaLabel(int? value) {
    if (value == null) return '—';
    if (value > 0) return '+$value';
    return '$value';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
