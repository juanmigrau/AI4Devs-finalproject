import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';

class FinalStandingsList extends StatelessWidget {
  const FinalStandingsList({
    super.key,
    required this.entries,
    this.currentUserId,
    this.currentUserPhotoUrl,
  });

  final List<RankingEntry> entries;
  final String? currentUserId;
  final String? currentUserPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const SizedBox(width: 24),
              const Expanded(flex: 3, child: SizedBox()),
              SizedBox(
                width: 52,
                child: Text(
                  'Total',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                _FinalStandingRow(
                  entry: entries[index],
                  photoURL: entries[index].player.userId == currentUserId
                      ? currentUserPhotoUrl
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FinalStandingRow extends StatelessWidget {
  const _FinalStandingRow({required this.entry, this.photoURL});

  final RankingEntry entry;
  final String? photoURL;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final player = entry.player;

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
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  PlayerInitialAvatar(
                    name: player.displayName,
                    colorIndex: player.seatOrder,
                    photoURL: photoURL,
                    radius: 14,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      player.displayName,
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
