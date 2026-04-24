/// Severidad del diagnóstico.
///
/// ¿Qué hace?
/// Clasifica el estado de una revisión del sistema.
///
/// ¿Para qué sirve?
/// Para mostrar visualmente si algo está:
/// - bien
/// - incompleto
/// - roto
enum DiagnosticSeverity {
  ok,
  warning,
  error;

  /// Etiqueta amigable para la UI.
  String get label {
    switch (this) {
      case DiagnosticSeverity.ok:
        return 'OK';
      case DiagnosticSeverity.warning:
        return 'Advertencia';
      case DiagnosticSeverity.error:
        return 'Error';
    }
  }
}

/// Revisión puntual de un módulo o componente.
///
/// ¿Qué hace?
/// Representa el resultado de analizar una parte de la app.
///
/// ¿Para qué sirve?
/// Para construir una pantalla de diagnóstico clara y accionable.
class SystemDiagnosticCheck {
  final String id;
  final String title;
  final String message;
  final DiagnosticSeverity severity;
  final String? details;

  const SystemDiagnosticCheck({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.details,
  });
}

/// Resumen completo de diagnóstico del sistema.
///
/// ¿Qué hace?
/// Agrupa:
/// - fecha de generación
/// - conteos reales por módulo
/// - revisiones con estado
///
/// ¿Para qué sirve?
/// Para que una sola pantalla pueda mostrar
/// el estado real del proyecto.
class SystemDiagnosticsOverview {
  final DateTime generatedAt;

  final int habitsCount;
  final int habitLogsCount;

  final int routineCount;
  final int workoutsCount;
  final int finishedWorkoutsCount;
  final int workoutSetsCount;

  final int nutritionLogsCount;
  final bool hasNutritionGoal;

  final int healthSnapshotsCount;
  final bool isHealthSupported;
  final bool hasHealthPermissions;
  final String? lastHealthSnapshotDateKey;

  final int dailyMissionClaimsCount;
  final int weeklyRewardClaimsCount;

  final bool hasRpgProfileSettings;

  final List<SystemDiagnosticCheck> checks;

  const SystemDiagnosticsOverview({
    required this.generatedAt,
    required this.habitsCount,
    required this.habitLogsCount,
    required this.routineCount,
    required this.workoutsCount,
    required this.finishedWorkoutsCount,
    required this.workoutSetsCount,
    required this.nutritionLogsCount,
    required this.hasNutritionGoal,
    required this.healthSnapshotsCount,
    required this.isHealthSupported,
    required this.hasHealthPermissions,
    required this.lastHealthSnapshotDateKey,
    required this.dailyMissionClaimsCount,
    required this.weeklyRewardClaimsCount,
    required this.hasRpgProfileSettings,
    required this.checks,
  });

  /// Cantidad de checks que están completamente bien.
  int get okCount =>
      checks.where((check) => check.severity == DiagnosticSeverity.ok).length;

  /// Cantidad de checks con advertencia.
  int get warningCount => checks
      .where((check) => check.severity == DiagnosticSeverity.warning)
      .length;

  /// Cantidad de checks con error.
  int get errorCount => checks
      .where((check) => check.severity == DiagnosticSeverity.error)
      .length;
}
