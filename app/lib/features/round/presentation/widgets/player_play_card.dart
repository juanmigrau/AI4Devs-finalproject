import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';

class PlayerPlayCard extends StatelessWidget {
  const PlayerPlayCard({
    super.key,
    required this.player,
    required this.index,
    required this.bid,
    required this.isDealer,
  });

  final PlayerEmbed player;
  final int index;
  final int bid;
  final bool isDealer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            PlayerInitialAvatar(
              name: player.displayName,
              colorIndex: index,
              radius: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      player.displayName,
                      style: textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isDealer) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.style,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
            Semantics(
              label: '${player.displayName} apostó $bid',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'apostó',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$bid',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Semantics(
              label:
                  '${player.displayName} tiene ${player.totalScore} puntos',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'puntos',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${player.totalScore}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
