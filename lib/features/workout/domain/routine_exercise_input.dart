import 'muscle_group.dart';

/// Ejercicio que forma parte de una rutina.
///
/// ¿Qué hace?
/// Representa un ejercicio editable y ordenado dentro de la rutina.
///
/// ¿Para qué sirve?
/// Para transportar los ejercicios entre repositorio, controlador y UI.
class RoutineExerciseInput {
  final String name;
  final MuscleGroup muscleGroup;

  const RoutineExerciseInput({
    required this.name,
    required this.muscleGroup,
  });
}