import 'routine_exercise_input.dart';

/// Detalle completo de una rutina.
///
/// ¿Qué hace?
/// Representa la rutina con su lista completa de ejercicios.
///
/// ¿Para qué sirve?
/// Para formularios avanzados y para iniciar una sesión de entrenamiento.
class WorkoutRoutineDetail {
  final String id;
  final String name;
  final String? description;
  final List<RoutineExerciseInput> exercises;

  const WorkoutRoutineDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
  });
}