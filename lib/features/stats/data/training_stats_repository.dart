import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/weekly_training_volume.dart';

/// Repositorio de estadísticas de entrenamiento.
///
/// ¿Qué hace?
/// Lee datos reales de entrenamiento desde Drift.
///
/// ¿Para qué sirve?
/// Para calcular métricas como volumen semanal y análisis automático
/// sin meter lógica dentro de la UI.
class TrainingStatsRepository {
  final AppDatabase db;

  const TrainingStatsRepository(this.db);

  /// Obtiene volumen semanal de entrenamiento.
  ///
  /// Fórmula:
  /// - Si hay peso: reps × peso.
  /// - Si no hay peso: reps, útil para calistenia.
  ///
  /// Edge cases:
  /// - Isométricos sin reps cuentan como 0 para volumen.
  /// - Sólo usa entrenamientos finalizados.
  /// - Devuelve semanas vacías para mantener la gráfica estable.
  Future<List<WeeklyTrainingVolume>> getWeeklyTrainingVolume({
    int weeks = 8,
  }) async {
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);
    final firstWeekStart = currentWeekStart.subtract(
      Duration(days: 7 * (weeks - 1)),
    );

    final buckets = <DateTime, _WeeklyAccumulator>{};

    for (var i = 0; i < weeks; i++) {
      final weekStart = firstWeekStart.add(Duration(days: i * 7));
      buckets[weekStart] = _WeeklyAccumulator();
    }

    final query =
        db.select(db.workoutSets).join([
          innerJoin(
            db.workouts,
            db.workouts.id.equalsExp(db.workoutSets.workoutId),
          ),
        ])..where(
          db.workouts.endedAt.isNotNull() &
              db.workoutSets.createdAt.isBiggerOrEqualValue(firstWeekStart),
        );

    final rows = await query.get();

    for (final row in rows) {
      final set = row.readTable(db.workoutSets);
      final weekStart = _startOfWeek(set.createdAt);
      final bucket = buckets[weekStart];

      if (bucket == null) continue;

      final reps = set.reps ?? 0;
      final weight = set.weight ?? 0.0;
      final volume = weight > 0 ? reps * weight : reps.toDouble();

      bucket.volume += volume;
      bucket.totalSets++;
      bucket.workoutIds.add(set.workoutId);
    }

    return buckets.entries.map((entry) {
      return WeeklyTrainingVolume(
        weekStart: entry.key,
        label: '${entry.key.day}/${entry.key.month}',
        volume: entry.value.volume,
        totalSets: entry.value.totalSets,
        workoutCount: entry.value.workoutIds.length,
      );
    }).toList();
  }

  /// Analiza el volumen semanal.
  ///
  /// ¿Qué hace?
  /// Compara:
  /// - semana actual
  /// - semana anterior
  /// - mejor semana del rango consultado
  ///
  /// ¿Para qué sirve?
  /// Para mostrar feedback tipo:
  /// "Subiste +40% vs semana pasada".
  Future<WeeklyTrainingVolumeAnalysis> getWeeklyVolumeAnalysis({
    int weeks = 8,
  }) async {
    final data = await getWeeklyTrainingVolume(weeks: weeks);

    if (data.isEmpty || data.every((item) => item.volume <= 0)) {
      return const WeeklyTrainingVolumeAnalysis(
        trend: WeeklyVolumeTrend.noData,
        currentVolume: 0,
        previousVolume: 0,
        difference: 0,
        percentageChange: 0,
        isBestWeek: false,
        title: 'Sin datos suficientes',
        message: 'Finaliza entrenamientos para analizar tu progreso semanal.',
      );
    }

    final current = data.last;
    final previous = data.length >= 2 ? data[data.length - 2] : null;

    final bestVolume = data
        .map((item) => item.volume)
        .fold<double>(0, (max, value) => value > max ? value : max);

    final isBestWeek = current.volume > 0 && current.volume >= bestVolume;

    if (previous == null || previous.volume <= 0) {
      return WeeklyTrainingVolumeAnalysis(
        trend: WeeklyVolumeTrend.firstData,
        currentVolume: current.volume,
        previousVolume: 0,
        difference: current.volume,
        percentageChange: 0,
        isBestWeek: isBestWeek,
        title: isBestWeek ? 'Primera marca registrada' : 'Progreso iniciado',
        message:
            'Ya tienes volumen registrado esta semana. Sigue entrenando para comparar contra la próxima.',
      );
    }

    final difference = current.volume - previous.volume;
    final percentageChange = (difference / previous.volume) * 100;

    if (difference.abs() < 0.01) {
      return WeeklyTrainingVolumeAnalysis(
        trend: WeeklyVolumeTrend.maintained,
        currentVolume: current.volume,
        previousVolume: previous.volume,
        difference: difference,
        percentageChange: 0,
        isBestWeek: isBestWeek,
        title: 'Volumen estable',
        message: 'Mantuviste el volumen de la semana pasada.',
      );
    }

    if (difference > 0) {
      return WeeklyTrainingVolumeAnalysis(
        trend: WeeklyVolumeTrend.increased,
        currentVolume: current.volume,
        previousVolume: previous.volume,
        difference: difference,
        percentageChange: percentageChange,
        isBestWeek: isBestWeek,
        title: isBestWeek ? 'Mejor semana registrada' : 'Volumen en aumento',
        message:
            'Subiste ${percentageChange.toStringAsFixed(0)}% vs la semana pasada.',
      );
    }

    return WeeklyTrainingVolumeAnalysis(
      trend: WeeklyVolumeTrend.decreased,
      currentVolume: current.volume,
      previousVolume: previous.volume,
      difference: difference,
      percentageChange: percentageChange,
      isBestWeek: isBestWeek,
      title: 'Volumen reducido',
      message:
          'Bajaste ${percentageChange.abs().toStringAsFixed(0)}% vs la semana pasada. Revisa descanso, constancia o intensidad.',
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }
}

class _WeeklyAccumulator {
  double volume = 0;
  int totalSets = 0;
  final Set<String> workoutIds = {};
}
