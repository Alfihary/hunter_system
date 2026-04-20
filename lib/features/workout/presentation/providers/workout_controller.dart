import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/drift_workout_repository.dart';
import '../../domain/routine_exercise_input.dart';
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
///
/// ¿Qué hace?
/// - carga rutinas
/// - crea rutina
/// - elimina rutina
/// - inicia y finaliza sesiones
/// - guarda sets
///
/// ¿Para qué sirve?
/// Para que la UI no implemente lógica de negocio.
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
///
/// ¿Qué hace?
/// Carga la rutina completa por ID.
///
/// ¿Para qué sirve?
/// Para iniciar una sesión con sus ejercicios.
final workoutRoutineDetailProvider =
    FutureProvider.family<WorkoutRoutineDetail?, String>(
  (ref, routineId) {
    final repository = ref.watch(workoutRepositoryProvider);
    return repository.getRoutineDetail(routineId);
  },
);

/// Provider reactivo de sets guardados en una sesión.
///
/// ¿Qué hace?
/// Escucha la tabla de sets del workout actual y emite cambios en vivo.
///
/// ¿Para qué sirve?
/// Para mostrar inmediatamente:
/// - total de sets
/// - sets por ejercicio
/// - detalle del historial dentro de la sesión
final workoutSetEntriesProvider =
    StreamProvider.family<List<WorkoutSetEntry>, String>(
  (ref, workoutId) {
    final repository = ref.watch(workoutRepositoryProvider);
    return repository.watchWorkoutSets(workoutId);
  },
);