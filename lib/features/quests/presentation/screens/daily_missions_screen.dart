import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily_mission.dart';
import '../../domain/weekly_quest_overview.dart';
import '../../domain/weekly_quest_reward.dart';
import '../providers/daily_mission_controller.dart';

/// Pantalla de misiones diarias.
///
/// ¿Qué hace?
/// Muestra:
/// - tablero semanal
/// - recompensas semanales
/// - misiones del día
/// - reclamo persistente de recompensas
///
/// ¿Para qué sirve?
/// Para convertir el sistema de quests en una progresión diaria + semanal.
class DailyMissionsScreen extends ConsumerWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(todayDailyMissionsProvider);
    final weeklyAsync = ref.watch(currentWeekQuestOverviewProvider);
    final actionState = ref.watch(dailyMissionActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Misiones diarias'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(todayDailyMissionsProvider);
              ref.invalidate(currentWeekQuestOverviewProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          weeklyAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(error.toString(), textAlign: TextAlign.center),
              ),
            ),
            data: (overview) => _WeeklyOverviewCard(
              overview: overview,
              isBusy: actionState.isLoading,
              onClaimReward: (rewardId) async {
                final error = await ref
                    .read(dailyMissionActionControllerProvider.notifier)
                    .claimWeeklyReward(rewardId);

                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          missionsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error.toString(), textAlign: TextAlign.center),
              ),
            ),
            data: (missions) {
              if (missions.isEmpty) {
                return const Center(
                  child: Text('No hay misiones disponibles hoy.'),
                );
              }

              final completedCount = missions
                  .where((mission) => mission.isCompleted)
                  .length;
              final claimedCount = missions
                  .where((mission) => mission.isClaimed)
                  .length;
              final claimedXp = missions
                  .where((mission) => mission.isClaimed)
                  .fold<int>(0, (sum, mission) => sum + mission.xpReward);

              return Column(
                children: [
                  _MissionSummaryCard(
                    completed: completedCount,
                    claimed: claimedCount,
                    total: missions.length,
                    claimedXp: claimedXp,
                  ),
                  const SizedBox(height: 12),
                  ...missions.map(
                    (mission) => _MissionCard(
                      key: ValueKey(mission.id),
                      mission: mission,
                      isBusy: actionState.isLoading,
                      onClaim: () async {
                        final error = await ref
                            .read(dailyMissionActionControllerProvider.notifier)
                            .claimMission(mission.id);

                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyOverviewCard extends StatelessWidget {
  final WeeklyQuestOverview overview;
  final bool isBusy;
  final Future<void> Function(String rewardId) onClaimReward;

  const _WeeklyOverviewCard({
    required this.overview,
    required this.isBusy,
    required this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Tablero semanal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(overview.weekStart)} - ${_formatDate(overview.weekEnd)}',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: overview.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              '${overview.totalClaims} / ${overview.maxClaims} quests reclamadas',
            ),
            const SizedBox(height: 4),
            Text('Días activos: ${overview.activeDays}'),
            const SizedBox(height: 4),
            Text('Días con tablero completo: ${overview.fullBoardDays}'),
            const SizedBox(height: 14),
            ...overview.rewards.map(
              (reward) => _WeeklyRewardCard(
                reward: reward,
                isBusy: isBusy,
                onClaim: () => onClaimReward(reward.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

class _WeeklyRewardCard extends StatelessWidget {
  final WeeklyQuestReward reward;
  final bool isBusy;
  final Future<void> Function() onClaim;

  const _WeeklyRewardCard({
    required this.reward,
    required this.isBusy,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reward.isClaimed
                      ? Icons.inventory_2
                      : reward.isUnlocked
                      ? Icons.auto_awesome
                      : Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reward.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('+${reward.xpReward} XP'),
              ],
            ),
            const SizedBox(height: 8),
            Text(reward.description),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: reward.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(reward.progressLabel),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (!reward.canClaim || isBusy) ? null : onClaim,
                child: Text(
                  reward.isClaimed
                      ? 'Recompensa reclamada'
                      : reward.canClaim
                      ? 'Reclamar recompensa semanal'
                      : 'Bloqueada',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionSummaryCard extends StatelessWidget {
  final int completed;
  final int claimed;
  final int total;
  final int claimedXp;

  const _MissionSummaryCard({
    required this.completed,
    required this.claimed,
    required this.total,
    required this.claimedXp,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (claimed / total).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Progreso del día',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text('$claimed / $total misiones reclamadas'),
            const SizedBox(height: 4),
            Text('$completed / $total completadas'),
            const SizedBox(height: 4),
            Text('XP reclamado hoy: $claimedXp'),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DailyMission mission;
  final bool isBusy;
  final Future<void> Function() onClaim;

  const _MissionCard({
    super.key,
    required this.mission,
    required this.isBusy,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = mission.isClaimed
        ? Colors.green
        : mission.isCompleted
        ? Colors.orange
        : mission.isAvailable
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  mission.isClaimed
                      ? Icons.workspace_premium
                      : mission.isCompleted
                      ? Icons.task_alt
                      : mission.isAvailable
                      ? Icons.radio_button_unchecked
                      : Icons.lock_outline,
                  color: statusColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mission.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Text('+${mission.xpReward} XP'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(mission.description),
            const SizedBox(height: 8),
            Text(
              'Categoría: ${mission.category.label}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: mission.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(mission.progressLabel),
            if (!mission.isAvailable && mission.unavailableReason != null) ...[
              const SizedBox(height: 8),
              Text(
                mission.unavailableReason!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (!mission.canClaim || isBusy) ? null : onClaim,
                child: Text(
                  mission.isClaimed
                      ? 'Reclamada'
                      : mission.canClaim
                      ? 'Reclamar recompensa'
                      : mission.isCompleted
                      ? 'Lista para reclamar'
                      : mission.isAvailable
                      ? 'En progreso'
                      : 'Bloqueada',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
