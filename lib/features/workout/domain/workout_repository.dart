import 'exercise_last_session_summary.dart';
import 'routine_exercise_input.dart';
import 'workout_history_detail.dart';
import 'workout_history_item.dart';
import 'workout_routine_detail.dart';
import 'workout_routine_summary.dart';
import 'workout_set_entry.dart';
import 'workout_set_type.dart';

/// Contrato del módulo de entrenamiento.
///
/// ¿Qué hace?
/// Define todas las operaciones disponibles para:
/// - rutinas
/// - sesiones
/// - sets
/// - comparación con la última sesión
/// - historial completo
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

  Stream<List<WorkoutSetEntry>> watchWorkoutSets(String workoutId);

  Future<Map<String, ExerciseLastSessionSummary>> getLastSessionComparison(
    String routineId,
  );

  /// Obtiene todas las sesiones terminadas ordenadas de más reciente a más antigua.
  Future<List<WorkoutHistoryItem>> getCompletedWorkouts();

  /// Obtiene el detalle completo de una sesión terminada.
  Future<WorkoutHistoryDetail?> getWorkoutHistoryDetail(String workoutId);

  Future<void> finishWorkout(String workoutId);
}
