import 'muscle_group.dart';

/// Bloques visuales de entrenamiento.
///
/// ¿Qué hace?
/// Agrupa ejercicios en pestañas horizontales más cómodas para la sesión.
///
/// ¿Para qué sirve?
/// Para que la pantalla de entrenamiento no se vea saturada.
/// El usuario puede enfocarse sólo en el bloque actual:
/// - empuje
/// - jalón
/// - piernas
/// - core
/// - full body
///
/// Nota:
/// Esto es una agrupación visual para la UI.
/// No reemplaza al grupo muscular técnico.
enum WorkoutBlock {
  push,
  pull,
  legs,
  core,
  fullBody;

  /// Texto visible en la interfaz.
  String get label {
    switch (this) {
      case WorkoutBlock.push:
        return 'EMPUJE';
      case WorkoutBlock.pull:
        return 'JALÓN';
      case WorkoutBlock.legs:
        return 'PIERNAS';
      case WorkoutBlock.core:
        return 'CORE';
      case WorkoutBlock.fullBody:
        return 'FULL BODY';
    }
  }

  /// Orden visual fijo de las tabs.
  int get sortIndex {
    switch (this) {
      case WorkoutBlock.push:
        return 0;
      case WorkoutBlock.legs:
        return 1;
      case WorkoutBlock.pull:
        return 2;
      case WorkoutBlock.core:
        return 3;
      case WorkoutBlock.fullBody:
        return 4;
    }
  }

  /// Mapea un grupo muscular técnico a un bloque visual.
  ///
  /// ¿Para qué sirve?
  /// Para no tener que agregar otra columna a la base de datos por ahora.
  static WorkoutBlock fromMuscleGroup(MuscleGroup group) {
    switch (group) {
      case MuscleGroup.chest:
      case MuscleGroup.shoulders:
      case MuscleGroup.triceps:
        return WorkoutBlock.push;

      case MuscleGroup.back:
      case MuscleGroup.biceps:
        return WorkoutBlock.pull;

      case MuscleGroup.quadriceps:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves:
        return WorkoutBlock.legs;

      case MuscleGroup.abs:
        return WorkoutBlock.core;

      case MuscleGroup.fullBody:
        return WorkoutBlock.fullBody;
    }
  }
}