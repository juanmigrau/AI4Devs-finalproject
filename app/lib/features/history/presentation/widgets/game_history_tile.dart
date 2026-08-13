import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';

class GameHistoryTile extends StatelessWidget {
  const GameHistoryTile({super.key, required this.item, required this.onTap});

  final GameHistoryItem item;
  final VoidCallback onTap;

  static const String _labelSeparator = ' — ';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parts = item.displayLabel.split(_labelSeparator);
    final formattedDate = parts.first;
    final playerNames = parts.length > 1
        ? parts.sublist(1).join(_labelSeparator)
        : '';

    final summaryText = item.winnerName != null
        ? '${item.playerCount} jugadores · '
              'Ganador: ${item.winnerName} (${item.winnerScore ?? 0} pts)'
        : '${item.playerCount} jugadores · Sin ganador';

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _SourceChip(source: item.source),
                  if (item.isSyncPending) ...[
                    const SizedBox(width: 4),
                    const _SyncPendingBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                playerNames,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summaryText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final GameHistorySource source;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLocal = source == GameHistorySource.local;
    final foreground = isLocal
        ? colorScheme.onSurfaceVariant
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocal ? colorScheme.surface : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocal ? Icons.phone_android : Icons.cloud_done,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            isLocal ? 'Local' : 'Nube',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncPendingBadge extends StatelessWidget {
  const _SyncPendingBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Pendiente',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
