/// Resumen global del módulo de hábitos.
///
/// ¿Qué hace?
/// Agrupa métricas que se muestran en el panel superior de la pantalla.
///
/// ¿Para qué sirve?
/// Para que la UI no tenga que recalcular estas métricas cada vez.
class HabitDashboard {
  final int totalHabits;
  final int completedToday;
  final int xpEarnedToday;
  final int xpEarnedOverall;

  const HabitDashboard({
    required this.totalHabits,
    required this.completedToday,
    required this.xpEarnedToday,
    required this.xpEarnedOverall,
  });
}