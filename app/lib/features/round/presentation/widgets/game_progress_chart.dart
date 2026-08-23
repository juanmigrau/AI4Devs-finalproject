import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:la_pocha/core/utils/player_colors.dart';
import 'package:la_pocha/features/round/domain/entities/game_stats.dart';
import 'package:la_pocha/features/round/presentation/widgets/chart_mode_toggle.dart';

class GameProgressChart extends StatefulWidget {
  const GameProgressChart({super.key, required this.stats});

  final GameStats stats;

  static const String emptyMessage =
      'Juega más rondas para ver la evolución';

  @override
  State<GameProgressChart> createState() => _GameProgressChartState();
}

class _GameProgressChartState extends State<GameProgressChart> {
  ChartMode _mode = ChartMode.points;

  @override
  Widget build(BuildContext context) {
    if (widget.stats.closedRoundCount < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            GameProgressChart.emptyMessage,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final series = widget.stats.progressSeries;
    final playerCount = series.length;
    final isPosition = _mode == ChartMode.position;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          ChartModeToggle(
            mode: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: widget.stats.closedRoundCount.toDouble(),
                minY: isPosition
                    ? 1
                    : _minScore(series).toDouble() - 5,
                maxY: isPosition
                    ? playerCount.toDouble()
                    : _maxScore(series).toDouble() + 5,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          'R${value.toInt()}',
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: isPosition ? 1 : null,
                      getTitlesWidget: (value, meta) {
                        if (isPosition && value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        final label = isPosition
                            ? '${_chartYToPosition(value, playerCount)}º'
                            : value.toInt().toString();
                        return Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: isPosition ? 1 : null,
                ),
                borderData: FlBorderData(show: true),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final s = series[spot.barIndex];
                        final point = s.points[spot.spotIndex];
                        return LineTooltipItem(
                          '${s.displayName}\n'
                          'Ronda ${point.roundNumber}\n'
                          'Puntos: ${point.cumulativeScore}\n'
                          'Posición: ${point.position}º',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  for (var i = 0; i < series.length; i++)
                    LineChartBarData(
                      spots: [
                        for (final point in series[i].points)
                          FlSpot(
                            point.roundNumber.toDouble(),
                            isPosition
                                ? _positionToChartY(
                                    point.position,
                                    playerCount,
                                  )
                                : point.cumulativeScore.toDouble(),
                          ),
                      ],
                      isCurved: false,
                      color: playerAvatarColorForIndex(series[i].seatOrder),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Legend(series: series),
        ],
      ),
    );
  }

  /// Maps rank 1 → top of chart (high Y).
  double _positionToChartY(int position, int playerCount) =>
      (playerCount + 1 - position).toDouble();

  int _chartYToPosition(double chartY, int playerCount) =>
      playerCount + 1 - chartY.round();

  int _minScore(List<PlayerProgressSeries> series) {
    var min = series.first.points.first.cumulativeScore;
    for (final s in series) {
      for (final p in s.points) {
        if (p.cumulativeScore < min) min = p.cumulativeScore;
      }
    }
    return min;
  }

  int _maxScore(List<PlayerProgressSeries> series) {
    var max = series.first.points.first.cumulativeScore;
    for (final s in series) {
      for (final p in s.points) {
        if (p.cumulativeScore > max) max = p.cumulativeScore;
      }
    }
    return max;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.series});

  final List<PlayerProgressSeries> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (final s in series)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: playerAvatarColorForIndex(s.seatOrder),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_initial(s.displayName)} ${s.displayName}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
      ],
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}
