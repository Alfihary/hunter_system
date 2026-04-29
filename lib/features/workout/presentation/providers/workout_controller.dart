import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../home/presentation/providers/home_dashboard_controller.dart';
import '../../../stats/presentation/providers/training_stats_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';
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
///
/// ¿Para qué sirve?
/// Permite que la capa de presentación use el módulo workout
/// sin depender directamente de Drift.
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftWorkoutRepository(db);
});

/// Controlador principal del módulo de entrenamiento.
///
/// ¿Qué hace?
/// Administra:
/// - listado de rutinas
/// - creación de rutinas
/// - eliminación de rutinas
/// - inicio de entrenamiento
/// - guardado de sets
/// - finalización de entrenamiento
///
/// ¿Para qué sirve?
/// Centraliza las acciones del módulo workout y refresca los módulos
/// conectados como Home y Stats.
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
      _refreshConnectedSystems();
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String> startWorkout(String routineId) async {
    final workoutId = await _repository.startWorkout(routineId);

    _refreshConnectedSystems();

    return workoutId;
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

      /// El XP no se duplica aquí.
      /// El RPG calcula XP desde los sets guardados en base de datos.
      /// Aquí sólo refrescamos las pantallas conectadas.
      _refreshConnectedSystems();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> finishWorkout(String workoutId) async {
    try {
      await _repository.finishWorkout(workoutId);

      ref.invalidate(completedWorkoutsProvider);
      ref.invalidate(workoutHistoryDetailProvider(workoutId));
      _refreshConnectedSystems();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getRoutineSummaries);
  }

  /// Refresca módulos derivados del entrenamiento.
  ///
  /// ¿Qué hace?
  /// Invalida providers que dependen de los datos de entrenamiento:
  /// - Home
  /// - Stats/RPG
  /// - Logros
  /// - Títulos
  ///
  /// ¿Para qué sirve?
  /// Para que al guardar sets o finalizar sesión el progreso se vea reflejado.
  void _refreshConnectedSystems() {
    ref.invalidate(homeDashboardControllerProvider);
    ref.invalidate(rpgControllerProvider);
    ref.invalidate(rpgAchievementsProvider);
    ref.invalidate(rpgTitlesProvider);
    ref.invalidate(weeklyTrainingVolumeProvider);
    ref.invalidate(weeklyTrainingVolumeAnalysisProvider);
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
