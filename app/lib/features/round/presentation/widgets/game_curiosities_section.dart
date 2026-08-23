import 'package:flutter/material.dart';
import 'package:la_pocha/features/round/domain/entities/game_curiosities.dart';

class GameCuriositiesSection extends StatelessWidget {
  const GameCuriositiesSection({super.key, required this.curiosities});

  final GameCuriosities curiosities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <({String title, String value})>[
      (
        title: 'Ronda más igualada',
        value: curiosities.mostEqualRoundNumber == null
            ? '—'
            : 'Ronda ${curiosities.mostEqualRoundNumber}',
      ),
      (
        title: 'Jugador más arriesgado',
        value: curiosities.riskiestPlayerName ?? '—',
      ),
      (
        title: 'Jugador más conservador',
        value: curiosities.mostConservativePlayerName ?? '—',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos curiosos',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(item.title),
                trailing: Text(
                  item.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
