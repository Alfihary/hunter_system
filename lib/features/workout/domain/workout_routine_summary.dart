/// Resumen de rutina para pantallas de listado.
///
/// ¿Qué hace?
/// Muestra sólo los datos necesarios para la lista principal.
///
/// ¿Para qué sirve?
/// Para no cargar detalles completos si no se necesitan todavía.
class WorkoutRoutineSummary {
  final String id;
  final String name;
  final String? description;
  final int exerciseCount;

  const WorkoutRoutineSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.exerciseCount,
  });
}