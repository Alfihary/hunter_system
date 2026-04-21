import 'muscle_group.dart';

/// Ejercicio que forma parte de una rutina.
///
/// ¿Qué hace?
/// Representa un ejercicio editable y ordenado dentro de una rutina.
///
/// ¿Para qué sirve?
/// Para transportar información entre:
/// - formulario
/// - repositorio
/// - detalle de rutina
///
/// Ahora también incluye `targetSets`, que representa
/// la meta de series planeadas para ese ejercicio.
class RoutineExerciseInput {
  final String name;
  final MuscleGroup muscleGroup;
  final int targetSets;

  const RoutineExerciseInput({
    required this.name,
    required this.muscleGroup,
    required this.targetSets,
  });
}
