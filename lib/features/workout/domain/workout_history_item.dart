/// Resumen de una sesión terminada.
///
/// ¿Qué hace?
/// Representa una entrada compacta para la pantalla de historial.
///
/// ¿Para qué sirve?
/// Para listar sesiones ya completadas sin cargar todavía todo el detalle.
class WorkoutHistoryItem {
  final String workoutId;
  final String routineId;
  final String routineName;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalSets;
  final double totalVolume;

  const WorkoutHistoryItem({
    required this.workoutId,
    required this.routineId,
    required this.routineName,
    required this.startedAt,
    required this.endedAt,
    required this.totalSets,
    required this.totalVolume,
  });

  /// Duración total de la sesión.
  Duration get duration => endedAt.difference(startedAt);
}
