/// Stats principales del personaje.
///
/// ¿Qué hace?
/// Representa los atributos centrales del sistema RPG.
///
/// ¿Para qué sirve?
/// Para transformar la actividad real del usuario en progreso visible.
///
/// Regla general:
/// - strength: empuje/jalón/pierna y trabajo físico fuerte
/// - endurance: volumen, isométricos y resistencia
/// - discipline: hábitos + adherencia constante
/// - recovery: nutrición útil para recuperación
/// - balance: equilibrio general de alimentación y actividad
/// - consistency: días activos de manera sostenida
class RpgStats {
  final int strength;
  final int endurance;
  final int discipline;
  final int recovery;
  final int balance;
  final int consistency;

  const RpgStats({
    required this.strength,
    required this.endurance,
    required this.discipline,
    required this.recovery,
    required this.balance,
    required this.consistency,
  });

  /// Valor más alto entre todos los stats.
  ///
  /// ¿Para qué sirve?
  /// Para escalar barras visuales en pantalla.
  int get maxValue {
    return [
      strength,
      endurance,
      discipline,
      recovery,
      balance,
      consistency,
    ].reduce((a, b) => a > b ? a : b);
  }
}