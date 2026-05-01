import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../health/domain/health_repository.dart';
import '../../nutrition/domain/meal_type.dart';
import '../domain/achievement.dart';
import '../domain/achievement_rarity.dart';
import '../domain/rpg_overview.dart';
import '../domain/rpg_rank.dart';
import '../domain/rpg_repository.dart';
import '../domain/rpg_source_breakdown.dart';
import '../domain/rpg_stats.dart';
import '../domain/rpg_title.dart';
import '../domain/rpg_text_catalog.dart';
import '../domain/rpg_text_key.dart';

/// Repositorio RPG derivado desde hábitos, entrenamiento, nutrición,
/// health y quests persistentes.
///
/// ¿Qué hace?
/// Lee las tablas existentes del sistema y calcula:
/// - XP
/// - nivel
/// - rango
/// - racha global
/// - stats
/// - logros
/// - títulos
///
/// ¿Para qué sirve?
/// Para conectar todo el ecosistema de la app al RPG
/// usando datos reales y persistidos.
class DerivedRpgRepository implements RpgRepository {
  final AppDatabase db;
  final HealthRepository healthRepository;

  DerivedRpgRepository(this.db, {required this.healthRepository});

  @override
  Future<RpgOverview> getOverview() async {
    final metrics = await _loadMetrics();
    final levelInfo = _calculateLevelInfo(metrics.totalXp);
    final rankInfo = _calculateRankInfo(metrics.totalXp);

    return RpgOverview(
      level: levelInfo.level,
      totalXp: metrics.totalXp,
      xpIntoCurrentLevel: levelInfo.xpIntoCurrentLevel,
      xpForNextLevel: levelInfo.xpForNextLevel,
      rank: rankInfo.rank,
      xpIntoCurrentRank: rankInfo.xpIntoCurrentRank,
      xpForNextRank: rankInfo.xpForNextRank,
      nextRank: rankInfo.nextRank,
      activeStreakDays: metrics.currentActivityStreak,
      stats: metrics.stats,
      breakdown: metrics.breakdown,
    );
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    final metrics = await _loadMetrics();

    final achievements = <Achievement>[
      _achievement(
        id: 'first_oath',
        name: 'Primer Juramento',
        description: 'Completa 1 hábito por primera vez.',
        rarity: AchievementRarity.common,
        current: metrics.habitCompletions,
        target: 1,
      ),
      _achievement(
        id: 'first_awakening',
        name: 'Primer Despertar',
        description: 'Completa tu primer entrenamiento.',
        rarity: AchievementRarity.common,
        current: metrics.finishedWorkouts,
        target: 1,
      ),
      _achievement(
        id: 'first_offering',
        name: 'Primera Ofrenda',
        description: 'Registra tu primer alimento.',
        rarity: AchievementRarity.common,
        current: metrics.nutritionLogsCount,
        target: 1,
      ),
      _achievement(
        id: 'chain_of_iron',
        name: 'Cadena de Hierro',
        description: 'Alcanza una racha global de 3 días.',
        rarity: AchievementRarity.rare,
        current: metrics.bestActivityStreak,
        target: 3,
      ),
      _achievement(
        id: 'will_of_steel',
        name: 'Voluntad de Acero',
        description: 'Alcanza una racha global de 7 días.',
        rarity: AchievementRarity.epic,
        current: metrics.bestActivityStreak,
        target: 7,
      ),
      _achievement(
        id: 'routine_sacred',
        name: 'Rutina Sagrada',
        description: 'Alcanza una racha global de 30 días.',
        rarity: AchievementRarity.legendary,
        current: metrics.bestActivityStreak,
        target: 30,
      ),
      _achievement(
        id: 'constant_hunter',
        name: RpgTextCatalog.get(RpgTextKey.achievementConstantIron),
        description: 'Completa 20 entrenamientos.',
        rarity: AchievementRarity.rare,
        current: metrics.finishedWorkouts,
        target: 20,
      ),
      _achievement(
        id: 'king_slayer_of_gym',
        name: 'Matarreyes del Gimnasio',
        description: 'Completa 50 entrenamientos.',
        rarity: AchievementRarity.epic,
        current: metrics.finishedWorkouts,
        target: 50,
      ),
      _achievement(
        id: 'destroyer_of_sets',
        name: 'Destructor de Series',
        description: 'Registra 100 sets.',
        rarity: AchievementRarity.rare,
        current: metrics.totalWorkoutSets,
        target: 100,
      ),
      _achievement(
        id: 'war_engine',
        name: 'Motor de Guerra',
        description: 'Registra 500 sets.',
        rarity: AchievementRarity.legendary,
        current: metrics.totalWorkoutSets,
        target: 500,
      ),
      _achievement(
        id: 'cruel_technique',
        name: 'Técnica Cruel',
        description: 'Completa 10 dropsets.',
        rarity: AchievementRarity.epic,
        current: metrics.dropSets,
        target: 10,
      ),
      _achievement(
        id: 'living_statue',
        name: 'Estatua Viviente',
        description: 'Completa 20 sets isométricos.',
        rarity: AchievementRarity.epic,
        current: metrics.isometricSets,
        target: 20,
      ),
      _achievement(
        id: 'warrior_protein',
        name: 'Proteína del Guerrero',
        description: 'Cumple proteína 3 días.',
        rarity: AchievementRarity.rare,
        current: metrics.nutritionProteinDays,
        target: 3,
      ),
      _achievement(
        id: 'table_of_conqueror',
        name: 'Mesa del Conquistador',
        description: 'Cumple calorías y proteína en 3 días.',
        rarity: AchievementRarity.rare,
        current: metrics.nutritionGoodDays,
        target: 3,
      ),
      _achievement(
        id: 'triad_complete',
        name: 'Tríada Completa',
        description:
            'Logra al menos 1 día con hábito + entrenamiento + nutrición.',
        rarity: AchievementRarity.epic,
        current: metrics.triadDays,
        target: 1,
      ),

      /// Health
      _achievement(
        id: 'first_step',
        name: RpgTextCatalog.get(RpgTextKey.achievementFirstStep),
        description: 'Registra tu primer día con pasos sincronizados.',
        rarity: AchievementRarity.common,
        current: metrics.healthRecordedDays,
        target: 1,
      ),
      _achievement(
        id: 'hunter_stride',
        name: RpgTextCatalog.get(RpgTextKey.achievementAscendingStride),
        description: 'Cumple la meta de pasos 3 días.',
        rarity: AchievementRarity.rare,
        current: metrics.stepGoalDays,
        target: 3,
      ),
      _achievement(
        id: 'sanctuary_march',
        name: 'Marcha del Santuario',
        description: 'Cumple la meta de pasos 7 días.',
        rarity: AchievementRarity.epic,
        current: metrics.stepGoalDays,
        target: 7,
      ),
      _achievement(
        id: 'sleep_of_steel',
        name: 'Sueño de Acero',
        description: 'Cumple tu meta de sueño 3 días.',
        rarity: AchievementRarity.rare,
        current: metrics.sleepGoalDays,
        target: 3,
      ),
      _achievement(
        id: 'night_rebirth',
        name: 'Renacer Nocturno',
        description: 'Cumple tu meta de sueño 7 días.',
        rarity: AchievementRarity.epic,
        current: metrics.sleepGoalDays,
        target: 7,
      ),
      _achievement(
        id: 'recovery_gate',
        name: 'Puerta de la Recuperación',
        description: 'Logra 3 días con pasos y sueño en meta el mismo día.',
        rarity: AchievementRarity.legendary,
        current: metrics.healthPerfectDays,
        target: 3,
      ),

      /// Quests diarias
      _achievement(
        id: 'first_contract',
        name: 'Primer Contrato',
        description: 'Reclama tu primera misión diaria.',
        rarity: AchievementRarity.common,
        current: metrics.questClaimsCount,
        target: 1,
      ),
      _achievement(
        id: 'keeper_of_contracts',
        name: 'Guardián de Contratos',
        description: 'Reclama 25 misiones diarias.',
        rarity: AchievementRarity.rare,
        current: metrics.questClaimsCount,
        target: 25,
      ),
      _achievement(
        id: 'master_of_board',
        name: 'Dominio del Tablón',
        description: 'Completa las 7 misiones del día en 3 ocasiones.',
        rarity: AchievementRarity.legendary,
        current: metrics.fullMissionBoardDays,
        target: 3,
      ),

      /// Recompensas semanales
      _achievement(
        id: 'first_weekly_cache',
        name: 'Primer Arcón Semanal',
        description: 'Reclama tu primera recompensa semanal.',
        rarity: AchievementRarity.rare,
        current: metrics.weeklyRewardClaimsCount,
        target: 1,
      ),
      _achievement(
        id: 'keeper_of_cycles',
        name: 'Guardián de Ciclos',
        description: 'Reclama 5 recompensas semanales.',
        rarity: AchievementRarity.epic,
        current: metrics.weeklyRewardClaimsCount,
        target: 5,
      ),

      _achievement(
        id: 'beyond_limit',
        name: 'Más Allá del Límite',
        description: 'Alcanza el rango SS.',
        rarity: AchievementRarity.legendary,
        current: metrics.totalXp,
        target: RpgRank.ss.minimumXp,
      ),
      _achievement(
        id: 'living_legend',
        name: 'Leyenda Viviente',
        description: 'Alcanza el rango SSS+.',
        rarity: AchievementRarity.mythic,
        current: metrics.totalXp,
        target: RpgRank.sssPlus.minimumXp,
      ),
    ];

    achievements.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }

      if (a.rarity.sortOrder != b.rarity.sortOrder) {
        return b.rarity.sortOrder.compareTo(a.rarity.sortOrder);
      }

      return a.name.compareTo(b.name);
    });

    return achievements;
  }

  @override
  Future<List<RpgTitle>> getTitles() async {
    final metrics = await _loadMetrics();
    final storedEquippedTitleId = await _getStoredEquippedTitleId();

    final rawTitles = <RpgTitle>[
      _title(
        id: 'awakened_fragile',
        name: 'Despertado Frágil',
        description: 'Has dado el primer paso fuera de la normalidad.',
        requirementText: 'Disponible desde el inicio',
        unlocked: true,
        sortOrder: 0,
      ),
      _title(
        id: 'threshold_hunter',
        name: RpgTextCatalog.get(RpgTextKey.titleThresholdBearer),
        description: 'Ya no eres un humano común. Has cruzado el umbral.',
        requirementText: 'Alcanza rango D',
        unlocked: metrics.rank.index >= RpgRank.d.index,
        sortOrder: 1,
      ),
      _title(
        id: 'abyss_tracker',
        name: 'Rastreador del Abismo',
        description: 'Has aprendido a moverte en la oscuridad del progreso.',
        requirementText: 'Alcanza rango C',
        unlocked: metrics.rank.index >= RpgRank.c.index,
        sortOrder: 2,
      ),
      _title(
        id: 'dungeon_executioner',
        name: 'Verdugo de Mazmorras',
        description: 'Cada sesión terminada te acerca más al dominio total.',
        requirementText: 'Alcanza rango B',
        unlocked: metrics.rank.index >= RpgRank.b.index,
        sortOrder: 3,
      ),
      _title(
        id: 'lord_of_the_hunt',
        name: RpgTextCatalog.get(RpgTextKey.titleSovereigntyOfHunt),
        description: 'Tu avance ya no parece humano; parece depredador.',
        requirementText: 'Alcanza rango A',
        unlocked: metrics.rank.index >= RpgRank.a.index,
        sortOrder: 4,
      ),
      _title(
        id: 'sanctuary_monarch',
        name: 'Monarca del Santuario',
        description: 'Tu cuerpo y tu disciplina empiezan a dominar el campo.',
        requirementText: 'Alcanza rango S',
        unlocked: metrics.rank.index >= RpgRank.s.index,
        sortOrder: 5,
      ),
      _title(
        id: 'heir_of_the_void',
        name: 'Heredero del Vacío',
        description: 'Has tocado un nivel que intimida incluso al abismo.',
        requirementText: 'Alcanza rango SS',
        unlocked: metrics.rank.index >= RpgRank.ss.index,
        sortOrder: 6,
      ),
      _title(
        id: 'sovereign_of_shadows',
        name: 'Soberano de las Sombras',
        description: 'La oscuridad ya no te sigue; ahora te pertenece.',
        requirementText: 'Alcanza rango SSS+',
        unlocked: metrics.rank.index >= RpgRank.sssPlus.index,
        sortOrder: 7,
      ),
      _title(
        id: 'iron_unbreakable',
        name: 'Hierro Inquebrantable',
        description:
            'Tu disciplina dejó de ser intención y se volvió identidad.',
        requirementText: 'Completa 100 hábitos',
        unlocked: metrics.habitCompletions >= 100,
        sortOrder: 20,
      ),
      _title(
        id: 'devourer_of_volume',
        name: 'Devorador de Volumen',
        description: 'Transformaste toneladas de esfuerzo en evolución.',
        requirementText: 'Supera 10,000 de volumen total',
        unlocked: metrics.totalWorkoutVolume >= 10000,
        sortOrder: 21,
      ),
      _title(
        id: 'architect_of_body',
        name: 'Arquitecto del Cuerpo',
        description:
            'Tu alimentación dejó de ser azar y se volvió construcción.',
        requirementText: 'Cumple 7 días de nutrición buena',
        unlocked: metrics.nutritionGoodDays >= 7,
        sortOrder: 22,
      ),
      _title(
        id: 'bearer_of_the_streak',
        name: 'Portador de la Racha',
        description: 'La constancia se volvió tu arma más afilada.',
        requirementText: 'Alcanza una racha global de 30 días',
        unlocked: metrics.bestActivityStreak >= 30,
        sortOrder: 23,
      ),
      _title(
        id: 'predator_of_progress',
        name: 'Predador del Progreso',
        description: 'No sólo avanzas: cazas tu mejor versión todos los días.',
        requirementText: 'Logra 7 días de tríada completa y llega a rango A',
        unlocked:
            metrics.triadDays >= 7 && metrics.rank.index >= RpgRank.a.index,
        sortOrder: 24,
      ),

      /// Health
      _title(
        id: 'pilgrim_of_sanctuary',
        name: 'Peregrino del Santuario',
        description:
            'Tus pasos dejaron de ser paseo; ahora son una ruta de ascenso.',
        requirementText: 'Cumple la meta de pasos 7 días',
        unlocked: metrics.stepGoalDays >= 7,
        sortOrder: 30,
      ),
      _title(
        id: 'reborn_of_abyss',
        name: 'Renacido del Abismo',
        description:
            'Dormir ya no es descanso común: es restauración de poder.',
        requirementText: 'Cumple la meta de sueño 7 días',
        unlocked: metrics.sleepGoalDays >= 7,
        sortOrder: 31,
      ),
      _title(
        id: 'walker_between_worlds',
        name: 'Caminante entre Mundos',
        description:
            'Has convertido movimiento y recuperación en una sola disciplina.',
        requirementText: 'Logra 5 días perfectos de Health',
        unlocked: metrics.healthPerfectDays >= 5,
        sortOrder: 32,
      ),

      /// Quests
      _title(
        id: 'agent_of_board',
        name: 'Agente del Tablón',
        description:
            'Las misiones dejaron de ser lista; se volvieron contrato.',
        requirementText: 'Reclama 25 misiones diarias',
        unlocked: metrics.questClaimsCount >= 25,
        sortOrder: 40,
      ),
      _title(
        id: 'arbiter_of_dawn',
        name: 'Árbitro del Alba',
        description:
            'Has dominado el día completo más de una vez. Eso ya no es suerte.',
        requirementText: 'Completa las 7 misiones del día en 3 ocasiones',
        unlocked: metrics.fullMissionBoardDays >= 3,
        sortOrder: 41,
      ),
      _title(
        id: 'warden_of_cycle',
        name: 'Guardián del Ciclo',
        description:
            'Ya no sólo cumples contratos: también dominas el ritmo de las semanas.',
        requirementText: 'Reclama 3 recompensas semanales',
        unlocked: metrics.weeklyRewardClaimsCount >= 3,
        sortOrder: 42,
      ),
    ];

    final unlockedTitles = rawTitles
        .where((title) => title.isUnlocked)
        .toList();

    String? equippedTitleId;
    if (storedEquippedTitleId != null &&
        unlockedTitles.any((title) => title.id == storedEquippedTitleId)) {
      equippedTitleId = storedEquippedTitleId;
    } else if (unlockedTitles.isNotEmpty) {
      unlockedTitles.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
      equippedTitleId = unlockedTitles.first.id;
    }

    final titles = rawTitles
        .map(
          (title) => RpgTitle(
            id: title.id,
            name: title.name,
            description: title.description,
            requirementText: title.requirementText,
            isUnlocked: title.isUnlocked,
            isEquipped: title.id == equippedTitleId,
            sortOrder: title.sortOrder,
          ),
        )
        .toList();

    titles.sort((a, b) {
      if (a.isEquipped != b.isEquipped) {
        return a.isEquipped ? -1 : 1;
      }

      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }

      return a.sortOrder.compareTo(b.sortOrder);
    });

    return titles;
  }

  @override
  Future<void> equipTitle(String titleId) async {
    final titles = await getTitles();

    final target = titles.where((title) => title.id == titleId).toList();
    if (target.isEmpty) {
      throw Exception('El título solicitado no existe.');
    }

    if (!target.first.isUnlocked) {
      throw Exception('Ese título aún no está desbloqueado.');
    }

    await _ensureProfileSettings();

    await (db.update(db.rpgProfileSettings)..where((t) => t.id.equals(1)))
        .write(RpgProfileSettingsCompanion(equippedTitleId: Value(titleId)));
  }

  Future<_RpgMetrics> _loadMetrics() async {
    try {
      await healthRepository.syncTodayToCache();
    } catch (_) {}

    final habits = await db.select(db.habits).get();
    final habitLogs = await db.select(db.habitLogs).get();

    final workouts = await db.select(db.workouts).get();
    final workoutSets = await db.select(db.workoutSets).get();

    final nutritionLogs = await db.select(db.nutritionLogs).get();
    final nutritionGoalRow = await (db.select(
      db.nutritionGoals,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    final healthDays = await healthRepository.getCachedDailyRecords(
      limitDays: 180,
    );

    final missionClaims = await db.select(db.dailyMissionClaims).get();
    final weeklyRewardClaims = await db
        .select(db.weeklyQuestRewardClaims)
        .get();

    final habitXpById = <String, int>{
      for (final habit in habits) habit.id: habit.xpReward,
    };

    final habitsXp = habitLogs.fold<int>(0, (sum, log) {
      return sum + (habitXpById[log.habitId] ?? 0);
    });

    final finishedWorkouts = workouts.where((w) => w.endedAt != null).toList();
    final dropSets = workoutSets
        .where((set) => set.setType == 'dropSet')
        .length;
    final isometricSets = workoutSets
        .where((set) => set.setType == 'isometric')
        .length;

    final totalWorkoutVolume = workoutSets.fold<double>(0, (sum, set) {
      if (set.reps != null && set.weight != null) {
        return sum + (set.reps! * set.weight!);
      }
      return sum;
    });

    final workoutsXp =
        (finishedWorkouts.length * 80) +
        (workoutSets.length * 10) +
        (dropSets * 5) +
        (isometricSets * 8);

    final groupedNutrition = <String, List<dynamic>>{};
    for (final log in nutritionLogs) {
      final key = _dateKey(log.loggedAt);
      groupedNutrition.putIfAbsent(key, () => []);
      groupedNutrition[key]!.add(log);
    }

    int nutritionXp = 0;
    int recoveryScore = 0;
    int balanceScore = 0;

    int nutritionProteinDays = 0;
    int nutritionGoodDays = 0;

    final proteinGoal = nutritionGoalRow?.proteinGoal ?? 160;
    final caloriesGoal = nutritionGoalRow?.caloriesGoal ?? 2200;
    final carbsGoal = nutritionGoalRow?.carbsGoal ?? 200;
    final fatsGoal = nutritionGoalRow?.fatsGoal ?? 70;

    for (final entry in groupedNutrition.entries) {
      final logs = entry.value.cast<dynamic>();

      final totalCalories = logs.fold<double>(
        0,
        (sum, item) => sum + item.calories,
      );
      final totalProtein = logs.fold<double>(
        0,
        (sum, item) => sum + item.protein,
      );
      final totalCarbs = logs.fold<double>(0, (sum, item) => sum + item.carbs);
      final totalFats = logs.fold<double>(0, (sum, item) => sum + item.fats);

      nutritionXp += 5;

      final proteinOk = totalProtein >= proteinGoal * 0.9;
      final caloriesOk =
          totalCalories >= caloriesGoal * 0.85 &&
          totalCalories <= caloriesGoal * 1.15;
      final carbsOk =
          totalCarbs >= carbsGoal * 0.7 && totalCarbs <= carbsGoal * 1.3;
      final fatsOk = totalFats >= fatsGoal * 0.7 && totalFats <= fatsGoal * 1.3;

      if (proteinOk) {
        nutritionXp += 20;
        recoveryScore += 4;
        nutritionProteinDays++;
      }

      if (caloriesOk) {
        nutritionXp += 15;
        balanceScore += 3;
      }

      if (caloriesOk && proteinOk) {
        nutritionGoodDays++;
      }

      if (carbsOk && fatsOk) {
        nutritionXp += 10;
        balanceScore += 3;
      }

      final mealTypesOfDay = logs.map((log) => log.mealType.toString()).toSet();
      if (mealTypesOfDay.length >= MealType.values.length) {
        nutritionXp += 5;
        balanceScore += 2;
      }
    }

    int healthXp = 0;
    int stepGoalDays = 0;
    int sleepGoalDays = 0;
    int healthPerfectDays = 0;

    int enduranceScore = 0;
    int consistencyScore = 0;

    final healthActiveDateKeys = <String>{};

    for (final day in healthDays) {
      if (day.steps > 0 || day.totalSleepMinutes > 0) {
        healthActiveDateKeys.add(day.dateKey);
      }

      if (day.steps >= 3000) {
        healthXp += 5;
        enduranceScore += 1;
      }
      if (day.steps >= 6000) {
        healthXp += 10;
        enduranceScore += 2;
      }
      if (day.steps >= day.goalSteps) {
        healthXp += 15;
        enduranceScore += 2;
        consistencyScore += 2;
        stepGoalDays++;
      }
      if (day.steps >= 10000) {
        healthXp += 20;
        enduranceScore += 2;
      }

      if (day.totalSleepMinutes >= 360) {
        healthXp += 10;
        recoveryScore += 2;
      }
      if (day.totalSleepMinutes >= day.goalSleepMinutes) {
        healthXp += 15;
        recoveryScore += 3;
        balanceScore += 2;
        sleepGoalDays++;
      }
      if (day.totalSleepMinutes >= 480) {
        healthXp += 10;
        recoveryScore += 2;
      }

      if (day.stepsGoalReached && day.sleepGoalReached) {
        healthXp += 10;
        balanceScore += 3;
        consistencyScore += 1;
        healthPerfectDays++;
      }
    }

    final dailyQuestsXp = missionClaims.fold<int>(
      0,
      (sum, claim) => sum + claim.xpReward,
    );

    final weeklyQuestsXp = weeklyRewardClaims.fold<int>(
      0,
      (sum, claim) => sum + claim.xpReward,
    );

    final questsXp = dailyQuestsXp + weeklyQuestsXp;

    final missionClaimsByDate = <String, int>{};
    for (final claim in missionClaims) {
      missionClaimsByDate[claim.dateKey] =
          (missionClaimsByDate[claim.dateKey] ?? 0) + 1;
    }

    final questClaimsCount = missionClaims.length;
    final weeklyRewardClaimsCount = weeklyRewardClaims.length;
    final fullMissionBoardDays = missionClaimsByDate.values
        .where((count) => count >= 7)
        .length;

    final breakdown = RpgSourceBreakdown(
      habitsXp: habitsXp,
      workoutsXp: workoutsXp,
      nutritionXp: nutritionXp,
      healthXp: healthXp,
      questsXp: questsXp,
    );

    final totalXp = breakdown.totalXp;
    final rank = RpgRank.fromTotalXp(totalXp);

    int strengthScore = 0;
    int disciplineScore = 0;

    disciplineScore += habitLogs.length * 2;
    disciplineScore += questClaimsCount;
    disciplineScore += weeklyRewardClaimsCount * 2;

    final uniqueHabitDays = habitLogs.map((log) => log.dateKey).toSet();
    consistencyScore += uniqueHabitDays.length;
    consistencyScore += fullMissionBoardDays * 2;

    for (final set in workoutSets) {
      switch (set.muscleGroupSnapshot) {
        case 'chest':
        case 'back':
        case 'shoulders':
        case 'triceps':
        case 'quadriceps':
          strengthScore += 2;
          break;

        case 'biceps':
        case 'hamstrings':
        case 'glutes':
          strengthScore += 1;
          enduranceScore += 1;
          break;

        case 'calves':
        case 'abs':
        case 'fullBody':
          enduranceScore += 2;
          break;

        default:
          enduranceScore += 1;
          break;
      }

      if (set.setType == 'dropSet') {
        enduranceScore += 1;
      }

      if (set.setType == 'isometric') {
        enduranceScore += 2;
      }
    }

    disciplineScore += finishedWorkouts.length * 3;

    final activityDateKeys = <String>{};
    final nutritionDateKeys = <String>{};
    final workoutDateKeys = <String>{};
    final habitDateKeys = <String>{};

    for (final log in habitLogs) {
      habitDateKeys.add(log.dateKey);
      activityDateKeys.add(log.dateKey);
    }

    for (final workout in finishedWorkouts) {
      final key = _dateKey(workout.startedAt);
      workoutDateKeys.add(key);
      activityDateKeys.add(key);
    }

    for (final log in nutritionLogs) {
      final key = _dateKey(log.loggedAt);
      nutritionDateKeys.add(key);
      activityDateKeys.add(key);
    }

    for (final day in healthDays) {
      if (day.steps > 0 || day.totalSleepMinutes > 0) {
        activityDateKeys.add(day.dateKey);
      }
    }

    consistencyScore += healthActiveDateKeys.length;

    final triadDays = activityDateKeys.where((key) {
      return habitDateKeys.contains(key) &&
          workoutDateKeys.contains(key) &&
          nutritionDateKeys.contains(key);
    }).length;

    final currentActivityStreak = _calculateCurrentStreak(activityDateKeys);
    final bestActivityStreak = _calculateBestStreak(activityDateKeys);

    final stats = RpgStats(
      strength: strengthScore,
      endurance: enduranceScore,
      discipline: disciplineScore,
      recovery: recoveryScore,
      balance: balanceScore,
      consistency: consistencyScore,
    );

    return _RpgMetrics(
      totalXp: totalXp,
      rank: rank,
      stats: stats,
      breakdown: breakdown,
      habitCompletions: habitLogs.length,
      finishedWorkouts: finishedWorkouts.length,
      totalWorkoutSets: workoutSets.length,
      dropSets: dropSets,
      isometricSets: isometricSets,
      totalWorkoutVolume: totalWorkoutVolume,
      nutritionLogsCount: nutritionLogs.length,
      nutritionProteinDays: nutritionProteinDays,
      nutritionGoodDays: nutritionGoodDays,
      triadDays: triadDays,
      currentActivityStreak: currentActivityStreak,
      bestActivityStreak: bestActivityStreak,
      healthRecordedDays: healthDays.length,
      stepGoalDays: stepGoalDays,
      sleepGoalDays: sleepGoalDays,
      healthPerfectDays: healthPerfectDays,
      questClaimsCount: questClaimsCount,
      weeklyRewardClaimsCount: weeklyRewardClaimsCount,
      fullMissionBoardDays: fullMissionBoardDays,
    );
  }

  Achievement _achievement({
    required String id,
    required String name,
    required String description,
    required AchievementRarity rarity,
    required int current,
    required int target,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      rarity: rarity,
      currentProgress: current,
      targetProgress: target,
      isUnlocked: current >= target,
    );
  }

  RpgTitle _title({
    required String id,
    required String name,
    required String description,
    required String requirementText,
    required bool unlocked,
    required int sortOrder,
  }) {
    return RpgTitle(
      id: id,
      name: name,
      description: description,
      requirementText: requirementText,
      isUnlocked: unlocked,
      isEquipped: false,
      sortOrder: sortOrder,
    );
  }

  Future<String?> _getStoredEquippedTitleId() async {
    final row = await (db.select(
      db.rpgProfileSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    return row?.equippedTitleId;
  }

  Future<void> _ensureProfileSettings() async {
    final row = await (db.select(
      db.rpgProfileSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    if (row == null) {
      await db
          .into(db.rpgProfileSettings)
          .insert(
            RpgProfileSettingsCompanion.insert(id: const Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  _LevelInfo _calculateLevelInfo(int totalXp) {
    int level = 1;
    int remainingXp = totalXp;

    while (remainingXp >= level * 100) {
      remainingXp -= level * 100;
      level++;
    }

    return _LevelInfo(
      level: level,
      xpIntoCurrentLevel: remainingXp,
      xpForNextLevel: level * 100,
    );
  }

  _RankInfo _calculateRankInfo(int totalXp) {
    final currentRank = RpgRank.fromTotalXp(totalXp);
    final nextRank = currentRank.nextRank;

    if (nextRank == null) {
      return _RankInfo(
        rank: currentRank,
        xpIntoCurrentRank: 1,
        xpForNextRank: 1,
        nextRank: null,
      );
    }

    final currentFloor = currentRank.minimumXp;
    final nextFloor = nextRank.minimumXp;

    return _RankInfo(
      rank: currentRank,
      xpIntoCurrentRank: totalXp - currentFloor,
      xpForNextRank: nextFloor - currentFloor,
      nextRank: nextRank,
    );
  }

  int _calculateCurrentStreak(Set<String> dateKeys) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;

    while (true) {
      final day = today.subtract(Duration(days: streak));
      final key = _dateKey(day);

      if (dateKeys.contains(key)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateBestStreak(Set<String> dateKeys) {
    if (dateKeys.isEmpty) return 0;

    final dates = dateKeys.map((key) => DateTime.parse(key)).toList()..sort();

    int best = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      final previous = dates[i - 1];
      final currentDate = dates[i];
      final difference = currentDate.difference(previous).inDays;

      if (difference == 1) {
        current++;
        if (current > best) {
          best = current;
        }
      } else if (difference > 1) {
        current = 1;
      }
    }

    return best;
  }
}

class _LevelInfo {
  final int level;
  final int xpIntoCurrentLevel;
  final int xpForNextLevel;

  const _LevelInfo({
    required this.level,
    required this.xpIntoCurrentLevel,
    required this.xpForNextLevel,
  });
}

class _RankInfo {
  final RpgRank rank;
  final int xpIntoCurrentRank;
  final int xpForNextRank;
  final RpgRank? nextRank;

  const _RankInfo({
    required this.rank,
    required this.xpIntoCurrentRank,
    required this.xpForNextRank,
    required this.nextRank,
  });
}

class _RpgMetrics {
  final int totalXp;
  final RpgRank rank;
  final RpgStats stats;
  final RpgSourceBreakdown breakdown;

  final int habitCompletions;
  final int finishedWorkouts;
  final int totalWorkoutSets;
  final int dropSets;
  final int isometricSets;
  final double totalWorkoutVolume;

  final int nutritionLogsCount;
  final int nutritionProteinDays;
  final int nutritionGoodDays;

  final int triadDays;
  final int currentActivityStreak;
  final int bestActivityStreak;

  final int healthRecordedDays;
  final int stepGoalDays;
  final int sleepGoalDays;
  final int healthPerfectDays;

  final int questClaimsCount;
  final int weeklyRewardClaimsCount;
  final int fullMissionBoardDays;

  const _RpgMetrics({
    required this.totalXp,
    required this.rank,
    required this.stats,
    required this.breakdown,
    required this.habitCompletions,
    required this.finishedWorkouts,
    required this.totalWorkoutSets,
    required this.dropSets,
    required this.isometricSets,
    required this.totalWorkoutVolume,
    required this.nutritionLogsCount,
    required this.nutritionProteinDays,
    required this.nutritionGoodDays,
    required this.triadDays,
    required this.currentActivityStreak,
    required this.bestActivityStreak,
    required this.healthRecordedDays,
    required this.stepGoalDays,
    required this.sleepGoalDays,
    required this.healthPerfectDays,
    required this.questClaimsCount,
    required this.weeklyRewardClaimsCount,
    required this.fullMissionBoardDays,
  });
}
