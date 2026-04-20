import 'routine_exercise_input.dart';
import 'workout_routine_detail.dart';
import 'workout_routine_summary.dart';
import 'workout_set_entry.dart';
import 'workout_set_type.dart';

/// Contrato del módulo de entrenamiento.
///
/// ¿Qué hace?
/// Define todas las operaciones disponibles para rutinas, sesiones y sets.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la implementación concreta con Drift.
abstract class WorkoutRepository {
  Future<List<WorkoutRoutineSummary>> getRoutineSummaries();

  Future<WorkoutRoutineDetail?> getRoutineDetail(String routineId);

  Future<void> createRoutine({
    required String name,
    String? description,
    required List<RoutineExerciseInput> exercises,
  });

  Future<void> deleteRoutine(String routineId);

  Future<String> startWorkout(String routineId);

  Future<void> addWorkoutSet({
    required String workoutId,
    required String exerciseName,
    required String muscleGroup,
    required WorkoutSetType setType,
    int? reps,
    int? durationSeconds,
    double? weight,
  });

  /// Stream reactivo de sets guardados en una sesión.
  ///
  /// ¿Qué hace?
  /// Emite la lista actualizada de sets cada vez que cambia la sesión.
  ///
  /// ¿Para qué sirve?
  /// Para que la UI muestre automáticamente:
  /// - total de sets
  /// - sets por ejercicio
  /// - detalle en vivo
  Stream<List<WorkoutSetEntry>> watchWorkoutSets(String workoutId);

  Future<void> finishWorkout(String workoutId);
}