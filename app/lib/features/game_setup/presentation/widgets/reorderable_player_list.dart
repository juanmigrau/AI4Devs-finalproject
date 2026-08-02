import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/dealer_selector.dart';

class ReorderablePlayerList extends StatelessWidget {
  const ReorderablePlayerList({
    super.key,
    required this.players,
    required this.firstDealerPlayerId,
    required this.onReorder,
    required this.onDealerSelected,
  });

  final List<PlayerEmbed> players;
  final String firstDealerPlayerId;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String playerId) onDealerSelected;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: EdgeInsets.zero,
          itemCount: players.length,
          onReorderItem: onReorder,
          itemBuilder: (context, index) {
            final player = players[index];
            final isDealer = player.id == firstDealerPlayerId;
            final isLast = index == players.length - 1;

            return SizedBox(
              key: ValueKey(player.id),
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: dividerColor, width: 1),
                        ),
                ),
                child: _PlayerRow(
                  player: player,
                  index: index,
                  isDealer: isDealer,
                  onDealerSelected: () => onDealerSelected(player.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.index,
    required this.isDealer,
    required this.onDealerSelected,
  });

  final PlayerEmbed player;
  final int index;
  final bool isDealer;
  final VoidCallback onDealerSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.drag_handle,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${player.seatOrder}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          PlayerInitialAvatar(
            name: player.displayName,
            colorIndex: index,
            radius: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DealerSelector(
            isSelected: isDealer,
            onTap: onDealerSelected,
          ),
        ],
      ),
    );
  }
}
