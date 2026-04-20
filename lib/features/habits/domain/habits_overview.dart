import 'habit_dashboard.dart';
import 'habit_summary.dart';

/// Modelo agregado del módulo de hábitos.
///
/// ¿Qué hace?
/// Junta:
/// - lista de hábitos listos para mostrar
/// - métricas del dashboard
///
/// ¿Para qué sirve?
/// Para que el controlador exponga un único estado a la pantalla principal.
class HabitsOverview {
  final HabitDashboard dashboard;
  final List<HabitSummary> habits;

  const HabitsOverview({
    required this.dashboard,
    required this.habits,
  });
}