import 'workout_set_type.dart';

/// Detalle completo de una sesión de entrenamiento.
///
/// ¿Qué hace?
/// Agrupa todos los datos de una sesión terminada.
///
/// ¿Para qué sirve?
/// Para mostrar una pantalla de detalle rica:
/// - resumen general
/// - ejercicios trabajados
/// - sets ejecutados
class WorkoutHistoryDetail {
  final String workoutId;
  final String routineName;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalSets;
  final double totalVolume;
  final List<WorkoutHistoryExerciseGroup> exercises;

  const WorkoutHistoryDetail({
    required this.workoutId,
    required this.routineName,
    required this.startedAt,
    required this.endedAt,
    required this.totalSets,
    required this.totalVolume,
    required this.exercises,
  });

  Duration get duration => endedAt.difference(startedAt);
}

/// Grupo de sets pertenecientes al mismo ejercicio.
///
/// ¿Qué hace?
/// Agrupa las series de un ejercicio dentro de una sesión.
///
/// ¿Para qué sirve?
/// Para mostrar el detalle organizado por ejercicio.
class WorkoutHistoryExerciseGroup {
  final String exerciseName;
  final String muscleGroup;
  final List<WorkoutHistorySetEntry> sets;

  const WorkoutHistoryExerciseGroup({
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
  });
}

/// Set individual leído para una pantalla de historial.
///
/// ¿Qué hace?
/// Representa exactamente una serie ejecutada en una sesión pasada.
///
/// ¿Para qué sirve?
/// Para mostrar reps, duración, peso y tipo.
class WorkoutHistorySetEntry {
  final int setOrder;
  final WorkoutSetType setType;
  final int? reps;
  final int? durationSeconds;
  final double? weight;
  final DateTime createdAt;

  const WorkoutHistorySetEntry({
    required this.setOrder,
    required this.setType,
    required this.reps,
    required this.durationSeconds,
    required this.weight,
    required this.createdAt,
  });
}
