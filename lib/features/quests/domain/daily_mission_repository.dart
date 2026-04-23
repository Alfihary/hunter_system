import 'daily_mission.dart';
import 'weekly_quest_overview.dart';

/// Contrato del módulo de misiones diarias.
///
/// ¿Qué hace?
/// Define lectura y reclamación de:
/// - misiones del día
/// - recompensas semanales
///
/// ¿Para qué sirve?
/// Para desacoplar la UI del cálculo y persistencia real.
abstract class DailyMissionRepository {
  /// Obtiene las misiones del día actual.
  Future<List<DailyMission>> getTodayMissions();

  /// Reclama una misión del día actual.
  ///
  /// ¿Qué hace?
  /// Persiste que el usuario obtuvo esa recompensa hoy.
  ///
  /// ¿Para qué sirve?
  /// Para volver permanente el XP de la misión y evitar doble reclamo.
  Future<void> claimMission(String missionId);

  /// Obtiene el estado semanal actual del tablero.
  Future<WeeklyQuestOverview> getCurrentWeekOverview();

  /// Reclama una recompensa semanal.
  ///
  /// ¿Qué hace?
  /// Persiste el reclamo de una recompensa de semana actual.
  ///
  /// ¿Para qué sirve?
  /// Para otorgar bonus semanal una sola vez.
  Future<void> claimWeeklyReward(String rewardId);
}
