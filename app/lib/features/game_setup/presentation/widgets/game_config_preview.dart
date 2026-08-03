import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:la_pocha/core/config/debug_config_notifier.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/card_count_label.dart';

class GameConfigPreview extends StatelessWidget {
  const GameConfigPreview({
    super.key,
    required this.totalCards,
    required this.maxCardsPerRound,
    required this.totalRounds,
  });

  final int totalCards;
  final int maxCardsPerRound;
  final int totalRounds;

  @override
  Widget build(BuildContext context) {
    final debugConfig = kDebugMode && getIt.isRegistered<DebugConfigNotifier>()
        ? getIt<DebugConfigNotifier>()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _PreviewRow(
                  label: 'Cartas totales',
                  value: '$totalCards',
                  suffix: cardCountSuffix(totalCards),
                ),
                const SizedBox(height: 16),
                _PreviewRow(
                  label: 'Máx. por ronda',
                  value: '$maxCardsPerRound',
                  suffix: cardCountSuffix(maxCardsPerRound),
                ),
                const SizedBox(height: 16),
                _PreviewRow(
                  label: 'Total de rondas',
                  value: '$totalRounds',
                  suffix: 'rondas',
                ),
              ],
            ),
          ),
        ),
        if (debugConfig != null)
          ListenableBuilder(
            listenable: debugConfig,
            builder: (context, _) {
              if (!debugConfig.shortGameMode) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(child: _debugBadge(context)),
              );
            },
          ),
      ],
    );
  }

  Widget _debugBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '⚡ Modo debug',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            suffix,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
