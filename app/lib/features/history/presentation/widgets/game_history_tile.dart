import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/presentation/bloc/history_list_bloc.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';

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
                  _SyncStatusChip(item: item),
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

class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip({required this.item});

  final GameHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final syncStatus = item.syncStatus;
    if (syncStatus == SyncStatus.pending || syncStatus == SyncStatus.failed) {
      return _PendingSyncControls(item: item, syncStatus: syncStatus!);
    }

    return _SourceChip(source: item.source);
  }
}

class _PendingSyncControls extends StatelessWidget {
  const _PendingSyncControls({
    required this.item,
    required this.syncStatus,
  });

  final GameHistoryItem item;
  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFailed = syncStatus == SyncStatus.failed;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isFailed
              ? colorScheme.onErrorContainer
              : colorScheme.onTertiaryContainer,
        );

    return BlocBuilder<HistoryListBloc, HistoryListState>(
      buildWhen: (previous, current) {
        final previousIds = previous is HistoryListLoaded
            ? previous.syncingGameIds
            : const <String>{};
        final currentIds = current is HistoryListLoaded
            ? current.syncingGameIds
            : const <String>{};
        return previousIds.contains(item.id) != currentIds.contains(item.id);
      },
      builder: (context, state) {
        final isSyncing = state is HistoryListLoaded &&
            state.syncingGameIds.contains(item.id);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.only(right: 8),
              avatar: Icon(
                isFailed
                    ? Icons.cloud_off_outlined
                    : Icons.cloud_upload_outlined,
                size: 14,
                color: isFailed ? colorScheme.error : colorScheme.tertiary,
              ),
              label: Text(
                isFailed ? 'Error sync' : 'Pendiente',
                style: labelStyle,
              ),
              backgroundColor: isFailed
                  ? colorScheme.errorContainer
                  : colorScheme.tertiaryContainer,
            ),
            IconButton(
              icon: isSyncing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.refresh_outlined, size: 18),
              color: colorScheme.primary,
              tooltip: 'Reintentar sincronización',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: isSyncing
                  ? null
                  : () => context.read<HistoryListBloc>().add(
                        SyncRetryRequested(gameId: item.id),
                      ),
            ),
          ],
        );
      },
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
