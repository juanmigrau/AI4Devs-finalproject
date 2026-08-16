import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';

class WinnerCard extends StatelessWidget {
  const WinnerCard({super.key, required this.entry, this.photoURL});

  final RankingEntry entry;
  final String? photoURL;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final player = entry.player;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          PlayerInitialAvatar(
            name: player.displayName,
            colorIndex: player.seatOrder,
            photoURL: photoURL,
            radius: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.totalScore} puntos',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
