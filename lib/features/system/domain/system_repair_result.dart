/// Resultado de una acción de reparación del sistema.
///
/// ¿Qué hace?
/// Representa si una acción interna tuvo éxito o no,
/// junto con un mensaje explicativo.
///
/// ¿Para qué sirve?
/// Para que la UI pueda mostrar feedback claro después de ejecutar
/// una reparación o sincronización.
class SystemRepairResult {
  final bool success;
  final String message;

  const SystemRepairResult({required this.success, required this.message});
}
