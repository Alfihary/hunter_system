/// Item compacto para mostrar tareas/misiones/hábitos en Home.
class HomeDashboardItem {
  final String title;
  final String subtitle;
  final int xpReward;
  final bool isDone;
  final String iconKey;

  const HomeDashboardItem({
    required this.title,
    required this.subtitle,
    required this.xpReward,
    required this.isDone,
    required this.iconKey,
  });
}

/// Resumen principal del dashboard Home.
class HomeDashboardOverview {
  final DateTime generatedAt;

  final String rankLabel;
  final int level;
  final int totalXp;
  final int activeStreakDays;

  final int xpIntoCurrentRank;
  final int xpForNextRank;
  final String? nextRankLabel;

  final String? equippedTitleName;
  final String? equippedTitleDescription;

  final int totalTodayMissions;
  final int completedTodayMissions;
  final int claimableTodayMissions;
  final int claimedTodayMissions;
  final int claimedTodayMissionXp;

  final int completedHabitsToday;
  final int finishedWorkoutsToday;
  final int nutritionLogsToday;

  final bool isHealthSupported;
  final bool hasHealthPermissions;
  final int stepsToday;
  final int stepGoal;
  final int sleepMinutesToday;
  final int sleepGoalMinutes;

  final String focusMessage;

  final List<HomeDashboardItem> todayMissionItems;
  final List<HomeDashboardItem> todayHabitItems;

  const HomeDashboardOverview({
    required this.generatedAt,
    required this.rankLabel,
    required this.level,
    required this.totalXp,
    required this.activeStreakDays,
    required this.xpIntoCurrentRank,
    required this.xpForNextRank,
    required this.nextRankLabel,
    required this.equippedTitleName,
    required this.equippedTitleDescription,
    required this.totalTodayMissions,
    required this.completedTodayMissions,
    required this.claimableTodayMissions,
    required this.claimedTodayMissions,
    required this.claimedTodayMissionXp,
    required this.completedHabitsToday,
    required this.finishedWorkoutsToday,
    required this.nutritionLogsToday,
    required this.isHealthSupported,
    required this.hasHealthPermissions,
    required this.stepsToday,
    required this.stepGoal,
    required this.sleepMinutesToday,
    required this.sleepGoalMinutes,
    required this.focusMessage,
    required this.todayMissionItems,
    required this.todayHabitItems,
  });

  double get rankProgress {
    if (nextRankLabel == null) return 1.0;
    if (xpForNextRank <= 0) return 0.0;
    return (xpIntoCurrentRank / xpForNextRank).clamp(0.0, 1.0);
  }

  double get missionProgress {
    if (totalTodayMissions <= 0) return 0;
    return (completedTodayMissions / totalTodayMissions).clamp(0.0, 1.0);
  }

  double get stepsProgress {
    if (stepGoal <= 0) return 0;
    return (stepsToday / stepGoal).clamp(0.0, 1.0);
  }

  double get sleepProgress {
    if (sleepGoalMinutes <= 0) return 0;
    return (sleepMinutesToday / sleepGoalMinutes).clamp(0.0, 1.0);
  }

  double get sleepHours => sleepMinutesToday / 60.0;

  bool get hasEquippedTitle =>
      equippedTitleName != null && equippedTitleName!.trim().isNotEmpty;
}
