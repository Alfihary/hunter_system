import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/hunter_panel.dart';
import '../../../../shared/presentation/widgets/hunter_section_label.dart';
import '../../../../shared/presentation/widgets/hunter_tappable.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../quests/presentation/providers/daily_mission_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';
import '../../domain/home_dashboard_overview.dart';
import '../providers/home_dashboard_controller.dart';

/// Pantalla principal de Hunter System.
///
/// ¿Qué hace?
/// Muestra el resumen diario del usuario:
/// - bienvenida personalizada
/// - rango y XP
/// - misión del día
/// - estadísticas rápidas
/// - hábitos pendientes
///
/// ¿Para qué sirve?
/// Es el dashboard inicial de la app y conecta al usuario
/// con los módulos principales.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final dashboardAsync = ref.watch(homeDashboardControllerProvider);
    final user = authState.user;

    return Scaffold(
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (overview) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(todayDailyMissionsProvider);
              ref.invalidate(currentWeekQuestOverviewProvider);
              ref.invalidate(rpgControllerProvider);
              ref.invalidate(rpgAchievementsProvider);
              ref.invalidate(rpgTitlesProvider);
              ref.invalidate(healthControllerProvider);

              await ref.read(homeDashboardControllerProvider.notifier).reload();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              children: [
                _Header(
                  name: user?.name ?? 'Hunter',
                  welcomeTitle: user?.welcomeTitle ?? 'Bienvenido/a, Hunter',
                  overview: overview,
                ),
                const SizedBox(height: 22),

                HunterTappable(
                  onTap: () => context.push('/stats'),
                  child: _RankProgressCard(overview: overview),
                ),

                const SizedBox(height: 22),

                HunterTappable(
                  onTap: () => context.push('/missions'),
                  child: _MissionCard(overview: overview),
                ),

                const SizedBox(height: 24),

                const HunterSectionLabel('ESTADÍSTICAS RÁPIDAS'),
                const SizedBox(height: 12),

                _QuickStats(overview: overview),

                const SizedBox(height: 24),

                HunterTappable(
                  onTap: () => context.push('/habits'),
                  child: _HabitsCard(overview: overview),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Header superior del Home.
///
/// ¿Qué hace?
/// Muestra:
/// - avatar/rango
/// - bienvenida personalizada por género
/// - nombre del usuario
/// - título equipado
/// - XP total
///
/// ¿Para qué sirve?
/// Para que el usuario vea identidad RPG desde el primer momento.
class _Header extends StatelessWidget {
  final String name;
  final String welcomeTitle;
  final HomeDashboardOverview overview;

  const _Header({
    required this.name,
    required this.welcomeTitle,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RankAvatar(rank: overview.rankLabel),
        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HunterSectionLabel(welcomeTitle.toUpperCase()),
              const SizedBox(height: 6),
              Text(
                name.toUpperCase(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (overview.hasEquippedTitle) ...[
                const SizedBox(height: 4),
                Text(
                  overview.equippedTitleName!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 12),

        _XpPill(xp: overview.totalXp),
      ],
    );
  }
}

/// Avatar visual del rango actual.
class _RankAvatar extends StatelessWidget {
  final String rank;

  const _RankAvatar({required this.rank});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 74,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Text(rank, style: Theme.of(context).textTheme.headlineLarge),
    );
  }
}

/// Chip visual de XP total.
class _XpPill extends StatelessWidget {
  final int xp;

  const _XpPill({required this.xp});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surface,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        '⚡ $xp XP',
        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// Card de progreso de rango.
///
/// ¿Qué hace?
/// Muestra progreso hacia el siguiente rango RPG.
class _RankProgressCard extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _RankProgressCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HunterSectionLabel('PROGRESO DE RANGO'),
              const Spacer(),
              Text('Rango ${overview.rankLabel}'),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(value: overview.rankProgress),
          const SizedBox(height: 12),
          Text(
            overview.nextRankLabel == null
                ? 'Rango máximo'
                : '${overview.xpIntoCurrentRank} / ${overview.xpForNextRank}',
          ),
        ],
      ),
    );
  }
}

/// Card de misión diaria.
class _MissionCard extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _MissionCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('MISIÓN DE HOY'),
          const SizedBox(height: 12),
          ...overview.todayMissionItems.map(
            (item) => Row(
              children: [
                Icon(_iconFor(item.iconKey)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.title)),
                Text('+${item.xpReward} XP'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estadísticas rápidas del día.
///
/// ¿Qué hace?
/// Muestra acceso rápido a:
/// - racha actual
/// - entrenamientos terminados hoy
class _QuickStats extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _QuickStats({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: HunterTappable(
            onTap: () => context.push('/stats'),
            child: HunterPanel(child: Text('${overview.activeStreakDays}')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HunterTappable(
            onTap: () => context.push('/workouts'),
            child: HunterPanel(
              child: Text('${overview.finishedWorkoutsToday}'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Card resumida de hábitos del día.
class _HabitsCard extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _HabitsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('HÁBITOS DE HOY'),
          const SizedBox(height: 12),
          if (overview.todayHabitItems.isEmpty)
            Text(
              'No hay hábitos pendientes.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...overview.todayHabitItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(item.title),
              ),
            ),
        ],
      ),
    );
  }
}

/// Devuelve ícono según clave de misión.
IconData _iconFor(String key) {
  switch (key) {
    case 'training':
      return Icons.fitness_center;
    default:
      return Icons.bolt;
  }
}
