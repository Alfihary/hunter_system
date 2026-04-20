/// Categorías de hábitos disponibles.
///
/// ¿Qué hace?
/// Organiza los hábitos por tipo.
///
/// ¿Para qué sirve?
/// Para que la UI sea clara y, en el futuro,
/// puedas aplicar reglas RPG distintas por categoría.
enum HabitCategory {
  physical,
  nutrition,
  recovery,
  mental,
  control;

  /// Etiqueta amigable para mostrar al usuario.
  String get label {
    switch (this) {
      case HabitCategory.physical:
        return 'Físico';
      case HabitCategory.nutrition:
        return 'Nutrición';
      case HabitCategory.recovery:
        return 'Recuperación';
      case HabitCategory.mental:
        return 'Mental';
      case HabitCategory.control:
        return 'Control';
    }
  }

  /// Convierte el texto guardado en BD a enum seguro.
  static HabitCategory fromStorage(String rawValue) {
    return HabitCategory.values.firstWhere(
      (value) => value.name == rawValue,
      orElse: () => HabitCategory.mental,
    );
  }
}