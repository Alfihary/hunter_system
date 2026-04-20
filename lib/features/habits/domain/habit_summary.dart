import 'habit_category.dart';

/// Modelo de lectura para la UI de hábitos.
///
/// ¿Qué hace?
/// Une datos del hábito + estado calculado del día + racha.
///
/// ¿Para qué sirve?
/// Para que la pantalla no tenga que calcular nada compleja.
/// La UI sólo pinta lo que el repositorio ya preparó.
class HabitSummary {
  final String id;
  final String name;
  final HabitCategory category;
  final int xpReward;
  final bool completedToday;
  final int currentStreak;

  const HabitSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.xpReward,
    required this.completedToday,
    required this.currentStreak,
  });
}