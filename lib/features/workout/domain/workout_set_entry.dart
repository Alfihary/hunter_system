import 'workout_set_type.dart';

/// Modelo de lectura de un set guardado.
///
/// ¿Qué hace?
/// Representa un set ya persistido en la base de datos.
///
/// ¿Para qué sirve?
/// Para mostrar en la UI:
/// - cuántos sets lleva el usuario
/// - qué hizo en cada ejercicio
/// - si fue normal, dropset o isométrico
class WorkoutSetEntry {
  final String id;
  final String exerciseName;
  final String muscleGroup;
  final WorkoutSetType setType;
  final int? reps;
  final int? durationSeconds;
  final double? weight;
  final int setOrder;
  final DateTime createdAt;

  const WorkoutSetEntry({
    required this.id,
    required this.exerciseName,
    required this.muscleGroup,
    required this.setType,
    required this.reps,
    required this.durationSeconds,
    required this.weight,
    required this.setOrder,
    required this.createdAt,
  });
}