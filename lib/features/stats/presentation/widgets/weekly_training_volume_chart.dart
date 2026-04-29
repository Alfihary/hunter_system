import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/weekly_training_volume.dart';

/// Gráfica de volumen semanal.
///
/// ¿Qué hace?
/// Dibuja el volumen real de entrenamiento por semana.
///
/// ¿Para qué sirve?
/// Para que Stats muestre progreso visual real, no sólo números.
class WeeklyTrainingVolumeChart extends StatelessWidget {
  final List<WeeklyTrainingVolume> data;

  const WeeklyTrainingVolumeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Todavía no hay datos de volumen.')),
      );
    }

    final maxVolume = data
        .map((item) => item.volume)
        .fold<double>(0, (max, value) => value > max ? value : max);

    final spots = List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index].volume);
    });

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxVolume <= 0 ? 100 : maxVolume * 1.2,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 42),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
