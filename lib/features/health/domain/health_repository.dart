import 'health_daily_record.dart';
import 'health_overview.dart';

/// Contrato del módulo Health.
///
/// ¿Qué hace?
/// Define las operaciones necesarias para leer pasos y sueño,
/// además de guardar y consultar snapshots diarios.
///
/// ¿Para qué sirve?
/// Para desacoplar la UI y el RPG de la implementación concreta del plugin.
abstract class HealthRepository {
  /// Revisa si la app ya tiene permisos suficientes para leer pasos y sueño.
  Future<bool> hasPermissions();

  /// Solicita permisos de lectura para pasos y sueño.
  Future<bool> requestPermissions();

  /// Obtiene el resumen principal del día actual.
  Future<HealthOverview> getTodayOverview();

  /// Sincroniza el día actual a la cache local si hay permisos.
  ///
  /// ¿Para qué sirve?
  /// Para persistir un snapshot diario estable que luego pueda usar el RPG.
  Future<void> syncTodayToCache();

  /// Regresa snapshots diarios guardados en cache.
  ///
  /// [limitDays] controla cuántos días recientes devolver.
  Future<List<HealthDailyRecord>> getCachedDailyRecords({int limitDays = 90});
}
