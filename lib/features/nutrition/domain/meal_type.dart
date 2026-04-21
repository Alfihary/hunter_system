/// Tipos de comida del día.
///
/// ¿Qué hace?
/// Define las categorías principales bajo las cuales se agrupan
/// los alimentos registrados por el usuario.
///
/// ¿Para qué sirve?
/// Para organizar mejor la UI y el historial diario:
/// - desayuno
/// - comida
/// - cena
/// - snack
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  /// Etiqueta amigable para mostrar en pantalla.
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Desayuno';
      case MealType.lunch:
        return 'Comida';
      case MealType.dinner:
        return 'Cena';
      case MealType.snack:
        return 'Snack';
    }
  }

  /// Orden visual de aparición en la pantalla.
  int get sortOrder {
    switch (this) {
      case MealType.breakfast:
        return 0;
      case MealType.lunch:
        return 1;
      case MealType.dinner:
        return 2;
      case MealType.snack:
        return 3;
    }
  }

  /// Convierte el valor guardado en BD a enum seguro.
  static MealType fromStorage(String rawValue) {
    return MealType.values.firstWhere(
      (value) => value.name == rawValue,
      orElse: () => MealType.snack,
    );
  }
}
