import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/drift_workout_repository.dart';
import '../../domain/exercise_last_session_summary.dart';
import '../../domain/routine_exercise_input.dart';
import '../../domain/workout_history_detail.dart';
import '../../domain/workout_history_item.dart';
import '../../domain/workout_repository.dart';
import '../../domain/workout_routine_detail.dart';
import '../../domain/workout_routine_summary.dart';
import '../../domain/workout_set_entry.dart';
import '../../domain/workout_set_type.dart';

/// Provider del repositorio de entrenamiento.
///
/// ¿Qué hace?
/// Expone la implementación Drift como contrato abstracto.
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftWorkoutRepository(db);
});

/// Controlador principal del listado de rutinas.
class WorkoutController extends AsyncNotifier<List<WorkoutRoutineSummary>> {
  late final WorkoutRepository _repository;

  @override
  Future<List<WorkoutRoutineSummary>> build() async {
    _repository = ref.watch(workoutRepositoryProvider);
    return _repository.getRoutineSummaries();
  }

  Future<String?> createRoutine({
    required String name,
    String? description,
    required List<RoutineExerciseInput> exercises,
  }) async {
    try {
      await _repository.createRoutine(
        name: name,
        description: description,
        exercises: exercises,
      );

      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> deleteRoutine(String routineId) async {
    try {
      await _repository.deleteRoutine(routineId);
      await reload();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String> startWorkout(String routineId) {
    return _repository.startWorkout(routineId);
  }

  Future<String?> addWorkoutSet({
    required String workoutId,
    required String exerciseName,
    required String muscleGroup,
    required WorkoutSetType setType,
    int? reps,
    int? durationSeconds,
    double? weight,
  }) async {
    try {
      await _repository.addWorkoutSet(
        workoutId: workoutId,
        exerciseName: exerciseName,
        muscleGroup: muscleGroup,
        setType: setType,
        reps: reps,
        durationSeconds: durationSeconds,
        weight: weight,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> finishWorkout(String workoutId) async {
    try {
      await _repository.finishWorkout(workoutId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getRoutineSummaries);
  }
}

final workoutControllerProvider =
    AsyncNotifierProvider<WorkoutController, List<WorkoutRoutineSummary>>(
      WorkoutController.new,
    );

/// Provider de detalle de rutina.
final workoutRoutineDetailProvider =
    FutureProvider.family<WorkoutRoutineDetail?, String>((ref, routineId) {
      final repository = ref.watch(workoutRepositoryProvider);
      return repository.getRoutineDetail(routineId);
    });

/// Provider reactivo de sets guardados en una sesión.
final workoutSetEntriesProvider =
    StreamProvider.family<List<WorkoutSetEntry>, String>((ref, workoutId) {
      final repository = ref.watch(workoutRepositoryProvider);
      return repository.watchWorkoutSets(workoutId);
    });

/// Provider de comparación contra la última sesión completada.
final lastRoutineSessionComparisonProvider =
    FutureProvider.family<Map<String, ExerciseLastSessionSummary>, String>((
      ref,
      routineId,
    ) {
      final repository = ref.watch(workoutRepositoryProvider);
      return repository.getLastSessionComparison(routineId);
    });

/// Provider del historial de sesiones terminadas.
final completedWorkoutsProvider = FutureProvider<List<WorkoutHistoryItem>>((
  ref,
) {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getCompletedWorkouts();
});

/// Provider de detalle de una sesión terminada.
final workoutHistoryDetailProvider =
    FutureProvider.family<WorkoutHistoryDetail?, String>((ref, workoutId) {
      final repository = ref.watch(workoutRepositoryProvider);
      return repository.getWorkoutHistoryDetail(workoutId);
    });
