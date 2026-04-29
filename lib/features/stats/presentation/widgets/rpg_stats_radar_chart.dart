import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../rpg/domain/rpg_stats.dart';

/// Radar chart visual para los atributos RPG.
///
/// ¿Qué hace?
/// Dibuja los stats principales del cazador en formato radial:
/// - Strength
/// - Endurance
/// - Discipline
/// - Recovery
/// - Balance
/// - Consistency
///
/// ¿Para qué sirve?
/// Para que la pantalla Stats se sienta más como videojuego RPG.
class RpgStatsRadarChart extends StatelessWidget {
  final RpgStats stats;

  const RpgStatsRadarChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxValue = stats.maxValue < 100 ? 100.0 : stats.maxValue.toDouble();
    final primary = Theme.of(context).colorScheme.primary;

    final values = [
      stats.strength.toDouble(),
      stats.endurance.toDouble(),
      stats.discipline.toDouble(),
      stats.recovery.toDouble(),
      stats.balance.toDouble(),
      stats.consistency.toDouble(),
    ];

    final labels = ['STR', 'END', 'DISC', 'REC', 'BAL', 'CONS'];

    return SizedBox(
      height: 260,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          titlePositionPercentageOffset: 0.18,
          ticksTextStyle: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 10),
          titleTextStyle: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          getTitle: (index, angle) {
            return RadarChartTitle(text: labels[index], angle: angle);
          },
          dataSets: [
            RadarDataSet(
              fillColor: primary.withOpacity(0.22),
              borderColor: primary,
              entryRadius: 4,
              borderWidth: 3,
              dataEntries: values.map((value) {
                return RadarEntry(value: value.clamp(0, maxValue));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
