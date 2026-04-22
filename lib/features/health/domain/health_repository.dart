import 'health_overview.dart';

/// Contrato del módulo Health.
///
/// ¿Qué hace?
/// Define las operaciones necesarias para leer pasos y sueño.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI de la implementación concreta del plugin.
abstract class HealthRepository {
  /// Revisa si la app ya tiene permisos suficientes para leer pasos y sueño.
  Future<bool> hasPermissions();

  /// Solicita permisos de lectura para pasos y sueño.
  Future<bool> requestPermissions();

  /// Obtiene el resumen principal del día actual.
  Future<HealthOverview> getTodayOverview();
}
