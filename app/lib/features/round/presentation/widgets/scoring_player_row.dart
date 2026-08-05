import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/presentation/widgets/bid_input_stepper.dart';

enum ScoringPlayerRowStatus { pending, active, completed, editing }

class ScoringPlayerRow extends StatelessWidget {
  const ScoringPlayerRow({
    super.key,
    required this.player,
    required this.index,
    required this.status,
    this.tricks,
    this.draftTrick = 0,
    required this.cardsInRound,
    required this.canConfirmTrick,
    this.isDealer = false,
    this.onTrickChanged,
    this.onTrickConfirmed,
    this.onActivateEdit,
  });

  final PlayerEmbed player;
  final int index;
  final ScoringPlayerRowStatus status;
  final int? tricks;
  final int draftTrick;
  final int cardsInRound;
  final bool canConfirmTrick;
  final bool isDealer;
  final ValueChanged<int>? onTrickChanged;
  final VoidCallback? onTrickConfirmed;
  final VoidCallback? onActivateEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPending = status == ScoringPlayerRowStatus.pending;
    final isActive = status == ScoringPlayerRowStatus.active;
    final isEditing = status == ScoringPlayerRowStatus.editing;
    final isExpanded = isActive || isEditing;
    final opacity = isPending ? 0.4 : 1.0;

    final row = Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isExpanded ? 12 : 8,
        ),
        child: SizedBox(
          height: isExpanded ? 56 : 36,
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
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: isExpanded
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDealer) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.style,
                        color: AppTheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
              if (status == ScoringPlayerRowStatus.completed)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFD7ECE0),
                  child: Text(
                    '$tricks',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (isExpanded)
                BidInputStepper(
                  value: draftTrick,
                  min: 0,
                  max: cardsInRound,
                  onChanged: onTrickChanged ?? (_) {},
                  onConfirm: onTrickConfirmed ?? () {},
                  canConfirm: canConfirmTrick,
                ),
            ],
          ),
        ),
      ),
    );

    if (status == ScoringPlayerRowStatus.completed && onActivateEdit != null) {
      return InkWell(
        onTap: onActivateEdit,
        child: row,
      );
    }

    return row;
  }
}
