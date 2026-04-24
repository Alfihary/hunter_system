import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/hunter_progress_panel.dart';
import '../../../../shared/presentation/widgets/hunter_rank_badge.dart';
import '../../../../shared/presentation/widgets/hunter_section_title.dart';
import '../../../../shared/presentation/widgets/hunter_surface_card.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../quests/presentation/providers/daily_mission_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';
import '../../domain/home_dashboard_overview.dart';
import '../providers/home_dashboard_controller.dart';

/// Pantalla principal premium.
///
/// ¿Qué hace?
/// Presenta un resumen real de:
/// - identidad del jugador
/// - progreso RPG
/// - estado del día
/// - accesos rápidos
///
/// ¿Para qué sirve?
/// Para convertir la Home en el centro de mando de toda la app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final dashboardAsync = ref.watch(homeDashboardControllerProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hunter System'),
        actions: [
          IconButton(
            tooltip: 'Perfil del cazador',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Cambiar tema',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
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
              padding: const EdgeInsets.all(16),
              children: [
                _HeroCard(
                  playerName: user?.name ?? 'Jugador',
                  email: user?.email ?? 'Sin correo',
                  overview: overview,
                ),
                const SizedBox(height: 16),
                const HunterSectionTitle(
                  title: 'Prioridad actual',
                  subtitle: 'Lo más rentable que puedes hacer ahora',
                  icon: Icons.track_changes_outlined,
                ),
                const SizedBox(height: 10),
                _PriorityCard(message: overview.focusMessage),
                const SizedBox(height: 16),
                const HunterSectionTitle(
                  title: 'Acciones rápidas',
                  subtitle: 'Navegación central del sistema',
                  icon: Icons.dashboard_customize_outlined,
                ),
                const SizedBox(height: 10),
                const _QuickActionsCard(),
                const SizedBox(height: 16),
                const HunterSectionTitle(
                  title: 'Tablero de hoy',
                  subtitle: 'Estado actual de tus quests diarias',
                  icon: Icons.flag_outlined,
                ),
                const SizedBox(height: 10),
                _MissionProgressCard(overview: overview),
                const SizedBox(height: 16),
                const HunterSectionTitle(
                  title: 'Actividad del día',
                  subtitle: 'Resumen real de tus módulos principales',
                  icon: Icons.auto_graph_outlined,
                ),
                const SizedBox(height: 10),
                _ActivityGrid(overview: overview),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String playerName;
  final String email;
  final HomeDashboardOverview overview;

  const _HeroCard({
    required this.playerName,
    required this.email,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      highlighted: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            child: Icon(Icons.shield_moon_outlined),
          ),
          const SizedBox(height: 14),
          Text(
            playerName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(email, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          HunterRankBadge(rankLabel: overview.rankLabel),
          if (overview.hasEquippedTitle) ...[
            const SizedBox(height: 14),
            Text(
              overview.equippedTitleName!,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (overview.equippedTitleDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                overview.equippedTitleDescription!,
                textAlign: TextAlign.center,
              ),
            ],
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _HeroChip(label: 'Nivel ${overview.level}'),
              _HeroChip(label: '${overview.totalXp} XP'),
              _HeroChip(label: 'Racha ${overview.activeStreakDays}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;

  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.65),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.18),
        ),
      ),
      child: Text(label),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final String message;

  const _PriorityCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
            label: const Text('Perfil'),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/missions'),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Misiones'),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/rpg'),
            icon: const Icon(Icons.auto_graph_outlined),
            label: const Text('RPG'),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/workouts'),
            icon: const Icon(Icons.fitness_center),
            label: const Text('Entrenar'),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/nutrition'),
            icon: const Icon(Icons.restaurant_outlined),
            label: const Text('Nutrición'),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/health'),
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('Health'),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/system/diagnostics'),
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Diagnóstico'),
          ),
        ],
      ),
    );
  }
}

class _MissionProgressCard extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _MissionProgressCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return HunterProgressPanel(
      title: 'Misiones del día',
      value:
          '${overview.completedTodayMissions} / ${overview.totalTodayMissions}',
      subtitle:
          'Reclamables: ${overview.claimableTodayMissions} | Reclamadas: ${overview.claimedTodayMissions} | XP: ${overview.claimedTodayMissionXp}',
      progress: overview.missionProgress,
      icon: Icons.flag_outlined,
      highlighted: true,
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _ActivityGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final itemWidth = wide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Hábitos',
                value: '${overview.completedHabitsToday}',
                subtitle: 'completados hoy',
                icon: Icons.local_fire_department_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Entrenamiento',
                value: '${overview.finishedWorkoutsToday}',
                subtitle: 'sesión(es) finalizada(s)',
                icon: Icons.fitness_center,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Nutrición',
                value: '${overview.nutritionLogsToday}',
                subtitle: 'registro(s) hoy',
                icon: Icons.restaurant_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: HunterProgressPanel(
                title: 'Pasos',
                value: '${overview.stepsToday}',
                subtitle: overview.isHealthSupported
                    ? overview.hasHealthPermissions
                          ? '${overview.stepsToday} / ${overview.stepGoal}'
                          : 'Faltan permisos de Health'
                    : 'Health no disponible',
                progress:
                    overview.isHealthSupported && overview.hasHealthPermissions
                    ? overview.stepsProgress
                    : 0.0,
                icon: Icons.directions_walk,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: HunterProgressPanel(
                title: 'Sueño',
                value: '${overview.sleepHours.toStringAsFixed(1)} h',
                subtitle: overview.isHealthSupported
                    ? overview.hasHealthPermissions
                          ? '${overview.sleepMinutesToday} / ${overview.sleepGoalMinutes} min'
                          : 'Faltan permisos de Health'
                    : 'Health no disponible',
                progress:
                    overview.isHealthSupported && overview.hasHealthPermissions
                    ? overview.sleepProgress
                    : 0.0,
                icon: Icons.bedtime_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
