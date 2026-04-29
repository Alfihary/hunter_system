/// Resultado del análisis semanal de volumen.
enum WeeklyVolumeTrend { noData, firstData, increased, decreased, maintained }

/// Modelo de volumen semanal de entrenamiento.
///
/// ¿Qué hace?
/// Representa el volumen de una semana:
/// - con peso: reps × peso
/// - calistenia: reps
///
/// ¿Para qué sirve?
/// Para graficar progreso real de entrenamiento en Stats.
class WeeklyTrainingVolume {
  final DateTime weekStart;
  final String label;
  final double volume;
  final int totalSets;
  final int workoutCount;

  const WeeklyTrainingVolume({
    required this.weekStart,
    required this.label,
    required this.volume,
    required this.totalSets,
    required this.workoutCount,
  });
}

/// Análisis automático del volumen semanal.
///
/// ¿Qué hace?
/// Compara semana actual contra semana anterior y detecta récord.
///
/// ¿Para qué sirve?
/// Para mostrar feedback inteligente al usuario.
class WeeklyTrainingVolumeAnalysis {
  final WeeklyVolumeTrend trend;
  final double currentVolume;
  final double previousVolume;
  final double difference;
  final double percentageChange;
  final bool isBestWeek;
  final String title;
  final String message;

  const WeeklyTrainingVolumeAnalysis({
    required this.trend,
    required this.currentVolume,
    required this.previousVolume,
    required this.difference,
    required this.percentageChange,
    required this.isBestWeek,
    required this.title,
    required this.message,
  });
}
