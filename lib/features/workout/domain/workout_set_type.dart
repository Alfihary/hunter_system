/// Tipo de set realizado dentro de una sesión.
///
/// ¿Qué hace?
/// Define cómo debe interpretarse el set guardado.
///
/// ¿Para qué sirve?
/// Para modelar correctamente:
/// - sets normales
/// - dropsets
/// - sets isométricos
///
/// Esto evita usar múltiples booleanos ambiguos.
enum WorkoutSetType {
  normal,
  dropSet,
  isometric;

  /// Texto amigable para mostrar en UI.
  String get label {
    switch (this) {
      case WorkoutSetType.normal:
        return 'Normal';
      case WorkoutSetType.dropSet:
        return 'Dropset';
      case WorkoutSetType.isometric:
        return 'Isométrico';
    }
  }

  /// Indica si este tipo necesita repeticiones.
  bool get requiresReps => this != WorkoutSetType.isometric;

  /// Indica si este tipo necesita duración.
  bool get requiresDuration => this == WorkoutSetType.isometric;

  /// Convierte el texto guardado en BD a enum seguro.
  static WorkoutSetType fromStorage(String rawValue) {
    return WorkoutSetType.values.firstWhere(
      (value) => value.name == rawValue,
      orElse: () => WorkoutSetType.normal,
    );
  }
}