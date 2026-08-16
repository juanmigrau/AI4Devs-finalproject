import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';

class RoundResultPlayerRow extends StatelessWidget {
  const RoundResultPlayerRow({super.key, required this.entry, this.photoURL});

  final RankingEntry entry;
  final String? photoURL;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roundScore = entry.roundScore;
    final roundScoreLabel = '${roundScore >= 0 ? '+' : ''}$roundScore';
    final positionDelta = entry.positionDelta;

    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  PlayerInitialAvatar(
                    name: entry.player.displayName,
                    colorIndex: entry.player.seatOrder,
                    photoURL: photoURL,
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
                  if (positionDelta != null && positionDelta != 0) ...[
                    const SizedBox(width: 4),
                    _InlinePositionChange(positionDelta: positionDelta),
                  ],
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
          ],
        ),
      ),
    );
  }
}

class _InlinePositionChange extends StatelessWidget {
  const _InlinePositionChange({required this.positionDelta});

  final int positionDelta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUp = positionDelta > 0;
    final color = isUp ? colorScheme.primary : colorScheme.error;
    final icon = isUp ? Icons.arrow_upward : Icons.arrow_downward;
    final label = isUp ? '+$positionDelta' : '$positionDelta';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        Text(label, style: textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}
