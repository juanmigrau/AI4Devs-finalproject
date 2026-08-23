import 'package:flutter/material.dart';

enum ChartMode { points, position }

class ChartModeToggle extends StatelessWidget {
  const ChartModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ChartMode mode;
  final ValueChanged<ChartMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ChartMode>(
      segments: const [
        ButtonSegment(
          value: ChartMode.points,
          label: Text('Puntos'),
          icon: Icon(Icons.show_chart, size: 18),
        ),
        ButtonSegment(
          value: ChartMode.position,
          label: Text('Posición'),
          icon: Icon(Icons.leaderboard_outlined, size: 18),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
    );
  }
}
