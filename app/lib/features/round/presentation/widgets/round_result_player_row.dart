import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';

class RoundResultPlayerRow extends StatelessWidget {
  const RoundResultPlayerRow({
    super.key,
    required this.entry,
  });

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roundScore = entry.roundScore;
    final roundScoreLabel =
        '${roundScore >= 0 ? '+' : ''}$roundScore';
    final positionDelta = entry.positionDelta;

    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${entry.rank}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  PlayerInitialAvatar(
                    name: entry.player.displayName,
                    colorIndex: entry.player.seatOrder,
                    radius: 14,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      entry.player.displayName,
                      style: textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                roundScoreLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: roundScore >= 0
                      ? colorScheme.primary
                      : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${entry.totalScore}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 36,
              child: _PositionChange(
                positionDelta: positionDelta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionChange extends StatelessWidget {
  const _PositionChange({required this.positionDelta});

  final int? positionDelta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (positionDelta == null || positionDelta == 0) {
      return Text(
        '—',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      );
    }

    final isUp = positionDelta! > 0;
    final n = positionDelta!.abs();
    final color = isUp ? colorScheme.primary : colorScheme.error;
    final icon = isUp ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 14),
        Text(
          '$n',
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
