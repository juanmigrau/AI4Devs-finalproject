import 'package:flutter/material.dart';

class TricksBalanceBanner extends StatelessWidget {
  const TricksBalanceBanner({
    super.key,
    required this.bidSum,
    required this.cardsInRound,
  });

  final int bidSum;
  final int cardsInRound;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final differential = bidSum - cardsInRound;
    final isOver = differential > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Balance de bazas',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            isOver ? '+$differential' : '$differential',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isOver ? colorScheme.tertiary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
