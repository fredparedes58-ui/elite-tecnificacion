import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PlayerRadarChart extends StatelessWidget {
  final Map<String, double> stats;

  const PlayerRadarChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final ticks = [20.0, 40.0, 60.0, 80.0, 100.0];
    final features = stats.keys.toList();
    final data = stats.values.toList();

    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: data.map((d) => RadarEntry(value: d)).toList(),
              borderColor: Colors.cyan,
              fillColor: Colors.cyan.withAlpha(102),
              borderWidth: 2,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.white24),
          tickBorderData: const BorderSide(color: Colors.white24),
          ticksTextStyle: const TextStyle(color: Colors.white54, fontSize: 10),
          tickCount: ticks.length,
          getTitle: (index, angle) {
            // FINAL FIX: The correct parameter name is `titleStyle`
            return RadarChartTitle(
              text: features[index].toUpperCase(),
              angle: angle,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          },
          titlePositionPercentageOffset: 0.2,
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
