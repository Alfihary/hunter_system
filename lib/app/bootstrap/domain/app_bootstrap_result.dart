/// Resultado del proceso de arranque técnico.
///
/// ¿Qué hace?
/// Representa el estado final del bootstrap de la app,
/// incluyendo advertencias no críticas.
///
/// ¿Para qué sirve?
/// Para que la UI pueda mostrar con claridad:
/// - si el arranque fue exitoso
/// - qué partes se repararon
/// - si hubo advertencias no bloqueantes
class AppBootstrapResult {
  final DateTime completedAt;
  final bool baseConfigurationReady;
  final bool healthSyncAttempted;
  final bool healthSyncSucceeded;
  final List<String> warnings;

  const AppBootstrapResult({
    required this.completedAt,
    required this.baseConfigurationReady,
    required this.healthSyncAttempted,
    required this.healthSyncSucceeded,
    required this.warnings,
  });

  /// Indica si el bootstrap alcanzó el mínimo necesario para continuar.
  bool get isSuccessful => baseConfigurationReady;

  /// Resumen corto del resultado.
  String get summary {
    if (!isSuccessful) {
      return 'El sistema no logró completar el arranque mínimo.';
    }

    if (warnings.isEmpty) {
      return 'El sistema quedó listo sin advertencias.';
    }

    return 'El sistema quedó listo con ${warnings.length} advertencia(s).';
  }
}
