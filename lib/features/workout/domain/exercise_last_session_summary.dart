/// Resumen de rendimiento de un ejercicio en la última sesión completada.
///
/// ¿Qué hace?
/// Guarda los datos más útiles de comparación para un ejercicio:
/// - cuántas series se hicieron
/// - mejor número de repeticiones
/// - mejor duración isométrica
/// - peso más alto usado
/// - fecha de esa sesión
///
/// ¿Para qué sirve?
/// Para que la pantalla de entrenamiento pueda mostrarle al usuario
/// un punto de referencia inmediato contra la sesión anterior.
class ExerciseLastSessionSummary {
  final String exerciseName;
  final DateTime performedAt;
  final int totalSets;
  final int? bestReps;
  final int? bestDurationSeconds;
  final double? heaviestWeight;

  const ExerciseLastSessionSummary({
    required this.exerciseName,
    required this.performedAt,
    required this.totalSets,
    required this.bestReps,
    required this.bestDurationSeconds,
    required this.heaviestWeight,
  });
}
