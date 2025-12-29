import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PlayerRadarChart extends StatelessWidget {
  final Map<String, double> skills;

  const PlayerRadarChart({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    final features = skills.keys.toList();
    final data = skills.values.toList();

    return RadarChart(
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
        tickCount: 5,
        getTitle: (index, angle) {
          return RadarChartTitle(
            text: features[index].toUpperCase(),
            angle: angle,
          );
        },
        titlePositionPercentageOffset: 0.2,
      ),
    );
  }
}
