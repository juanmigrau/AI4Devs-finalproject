import 'package:flutter/material.dart';

class TricksBalanceIndicator extends StatelessWidget {
  const TricksBalanceIndicator({
    super.key,
    required this.availableTricks,
    this.zeroIsReady = false,
  });

  final int availableTricks;

  /// When true (scoring), zero means the sum is exact → primary color.
  /// When false (bidding), zero means no tricks left → error color.
  final bool zeroIsReady;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remainingColor = zeroIsReady
        ? (availableTricks == 0 ? colorScheme.primary : colorScheme.error)
        : (availableTricks == 0 ? colorScheme.error : colorScheme.primary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bazas restantes',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$availableTricks',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: remainingColor,
            ),
          ),
        ],
      ),
    );
  }
}
