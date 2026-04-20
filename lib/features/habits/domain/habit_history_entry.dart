/// Entrada de historial de un hábito para un día concreto.
///
/// ¿Qué hace?
/// Representa si el hábito estuvo completado o no en una fecha determinada.
///
/// ¿Para qué sirve?
/// Para dibujar la pantalla de historial sin que la UI tenga que inspeccionar logs crudos.
class HabitHistoryEntry {
  final DateTime date;
  final bool completed;
  final int xpEarned;

  const HabitHistoryEntry({
    required this.date,
    required this.completed,
    required this.xpEarned,
  });
}