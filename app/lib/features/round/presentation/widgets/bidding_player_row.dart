import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/presentation/widgets/bid_input_stepper.dart';
import 'package:la_pocha/features/round/presentation/widgets/forbidden_bid_warning.dart';

enum BiddingPlayerRowStatus { pending, active, completed, editing }

class BiddingPlayerRow extends StatelessWidget {
  const BiddingPlayerRow({
    super.key,
    required this.player,
    required this.index,
    required this.status,
    this.bid,
    required this.isDealer,
    this.draftBid = 0,
    required this.cardsInRound,
    this.forbiddenBid,
    required this.canConfirmBid,
    this.isSubmitting = false,
    this.onBidChanged,
    this.onBidConfirmed,
    this.onActivateEdit,
  });

  final PlayerEmbed player;
  final int index;
  final BiddingPlayerRowStatus status;
  final int? bid;
  final bool isDealer;
  final int draftBid;
  final int cardsInRound;
  final int? forbiddenBid;
  final bool canConfirmBid;
  final bool isSubmitting;
  final ValueChanged<int>? onBidChanged;
  final VoidCallback? onBidConfirmed;
  final VoidCallback? onActivateEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPending = status == BiddingPlayerRowStatus.pending;
    final isActive = status == BiddingPlayerRowStatus.active;
    final isEditing = status == BiddingPlayerRowStatus.editing;
    final isExpanded = isActive || isEditing;
    final opacity = isPending ? 0.4 : 1.0;

    final row = Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isExpanded ? 12 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
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
                  if (status == BiddingPlayerRowStatus.completed)
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFD7ECE0),
                      child: Text(
                        '$bid',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (isExpanded)
                    BidInputStepper(
                      value: draftBid,
                      min: 0,
                      max: cardsInRound,
                      onChanged: onBidChanged ?? (_) {},
                      onConfirm: onBidConfirmed ?? () {},
                      canConfirm: canConfirmBid,
                      isSubmitting: isSubmitting,
                    ),
                ],
              ),
            ),
            if (isDealer && forbiddenBid != null && !isPending) ...[
              const SizedBox(height: 4),
              ForbiddenBidWarning(forbiddenBid: forbiddenBid!),
            ],
          ],
        ),
      ),
    );

    if (status == BiddingPlayerRowStatus.completed && onActivateEdit != null) {
      return InkWell(
        onTap: onActivateEdit,
        child: row,
      );
    }

    return row;
  }
}
