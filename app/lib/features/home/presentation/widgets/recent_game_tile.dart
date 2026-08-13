import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/services/game_history_mapper.dart';

class RecentGameTile extends StatelessWidget {
  const RecentGameTile({
    super.key,
    required this.item,
    required this.onTap,
    this.now,
    this.mapper = const GameHistoryMapper(),
  });

  static const String labelSeparator = ' — ';

  final GameHistoryItem item;
  final VoidCallback onTap;
  final DateTime? now;
  final GameHistoryMapper mapper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = mapper.formatRelativeFinishedAt(
      item.finishedAt,
      now: now,
    );
    final playerNames = _playerNamesFromLabel(item.displayLabel);
    final winnerName = item.winnerName;

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedDate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  playerNames,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  winnerName == null ? 'Sin ganador' : 'Ganó $winnerName',
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
      ),
    );
  }

  static String _playerNamesFromLabel(String displayLabel) {
    final parts = displayLabel.split(labelSeparator);
    if (parts.length < 2) {
      return '';
    }
    return parts.sublist(1).join(labelSeparator);
  }
}
