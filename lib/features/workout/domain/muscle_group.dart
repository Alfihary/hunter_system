/// Grupos musculares básicos del sistema.
///
/// ¿Qué hace?
/// Normaliza los grupos musculares usados por rutinas y sets.
///
/// ¿Para qué sirve?
/// Para evitar strings libres por toda la app y preparar lógica futura
/// como stats RPG, balance muscular y fatiga.
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  abs,
  fullBody;

  String get label {
    switch (this) {
      case MuscleGroup.chest:
        return 'Pecho';
      case MuscleGroup.back:
        return 'Espalda';
      case MuscleGroup.shoulders:
        return 'Hombros';
      case MuscleGroup.biceps:
        return 'Bíceps';
      case MuscleGroup.triceps:
        return 'Tríceps';
      case MuscleGroup.quadriceps:
        return 'Cuádriceps';
      case MuscleGroup.hamstrings:
        return 'Femoral';
      case MuscleGroup.glutes:
        return 'Glúteos';
      case MuscleGroup.calves:
        return 'Pantorrilla';
      case MuscleGroup.abs:
        return 'Abdomen';
      case MuscleGroup.fullBody:
        return 'Cuerpo completo';
    }
  }

  static MuscleGroup fromStorage(String rawValue) {
    return MuscleGroup.values.firstWhere(
      (value) => value.name == rawValue,
      orElse: () => MuscleGroup.fullBody,
    );
  }
}