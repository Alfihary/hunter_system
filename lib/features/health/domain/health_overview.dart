import 'daily_steps_summary.dart';
import 'sleep_day_summary.dart';

/// Vista principal del módulo Health.
///
/// ¿Qué hace?
/// Agrupa en un solo modelo:
/// - plataforma soportada o no
/// - permisos
/// - resumen de pasos
/// - resumen de sueño
///
/// ¿Para qué sirve?
/// Para que la UI pinte todo desde un único objeto.
class HealthOverview {
  final DateTime date;
  final bool isSupportedPlatform;
  final bool hasPermissions;
  final DailyStepsSummary steps;
  final SleepDaySummary sleep;

  const HealthOverview({
    required this.date,
    required this.isSupportedPlatform,
    required this.hasPermissions,
    required this.steps,
    required this.sleep,
  });
}
