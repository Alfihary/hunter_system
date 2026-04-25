import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../quests/presentation/providers/daily_mission_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';
import '../../domain/home_dashboard_overview.dart';
import '../providers/home_dashboard_controller.dart';

/// Pantalla Inicio estilo Hunter System.
///
/// ¿Qué hace?
/// Muestra el resumen principal del usuario con estilo RPG:
/// - rango actual
/// - XP total
/// - progreso real al siguiente rango
/// - misiones del día
/// - estadísticas rápidas
/// - hábitos completados y pendientes hoy
///
/// ¿Para qué sirve?
/// Para que el usuario vea su progreso diario desde una sola vista
/// y pueda navegar rápido a los módulos principales.
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
                _Header(name: user?.name ?? 'Cazador', overview: overview),
                const SizedBox(height: 22),
                _Tappable(
                  onTap: () => context.push('/stats'),
                  child: _RankProgressCard(overview: overview),
                ),
                const SizedBox(height: 22),
                _Tappable(
                  onTap: () => context.push('/missions'),
                  child: _MissionCard(overview: overview),
                ),
                const SizedBox(height: 24),
                const _SectionLabel('ESTADÍSTICAS RÁPIDAS'),
                const SizedBox(height: 12),
                _QuickStats(overview: overview),
                const SizedBox(height: 24),
                _Tappable(
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

class _Header extends StatelessWidget {
  final String name;
  final HomeDashboardOverview overview;

  const _Header({required this.name, required this.overview});

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
              const _SectionLabel('BIENVENIDO, CAZADOR'),
              const SizedBox(height: 6),
              Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (overview.hasEquippedTitle) ...[
                const SizedBox(height: 4),
                Text(
                  overview.equippedTitleName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _RankAvatar extends StatelessWidget {
  final String rank;

  const _RankAvatar({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.5),
      ),
      child: Text(rank, style: Theme.of(context).textTheme.headlineLarge),
    );
  }
}

class _XpPill extends StatelessWidget {
  final int xp;

  const _XpPill({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF121827),
        border: Border.all(color: const Color(0xFF55C8FF).withOpacity(0.25)),
      ),
      child: Text(
        '⚡ $xp XP',
        style: const TextStyle(
          color: Color(0xFFFFD93D),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RankProgressCard extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _RankProgressCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final progress = overview.rankProgress;

    final progressText = overview.nextRankLabel == null
        ? 'Rango máximo alcanzado'
        : '${overview.xpIntoCurrentRank} / ${overview.xpForNextRank} XP para rango ${overview.nextRankLabel}';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel('PROGRESO DE RANGO'),
              const Spacer(),
              Text(
                'Rango ${overview.rankLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 12),
          Text(progressText, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _MissionCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final items = overview.todayMissionItems;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('MISIÓN DE HOY'),
          const SizedBox(height: 18),
          if (items.isEmpty)
            Text(
              'No hay misiones disponibles hoy.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(
                      _iconFor(item.iconKey),
                      color: item.isDone
                          ? const Color(0xFF55C8FF)
                          : const Color(0xFF8C7CFF),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SmallXp(xp: item.xpReward),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _QuickStats({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tappable(
            onTap: () => context.push('/stats'),
            child: _MiniCard(
              icon: Icons.local_fire_department,
              value: '${overview.activeStreakDays}',
              label: 'Racha',
              subLabel: 'días',
              color: Colors.redAccent,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Tappable(
            onTap: () => context.push('/workouts'),
            child: _MiniCard(
              icon: Icons.fitness_center,
              value: '${overview.finishedWorkoutsToday}',
              label: 'Entrenos',
              subLabel: 'hoy',
              color: const Color(0xFF55C8FF),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Tappable(
            onTap: () => context.push('/missions'),
            child: _MiniCard(
              icon: Icons.flag,
              value: '${overview.claimedTodayMissions}',
              label: 'Quests',
              subLabel: 'reclamadas',
              color: const Color(0xFF8C7CFF),
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitsCard extends StatelessWidget {
  final HomeDashboardOverview overview;

  const _HabitsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final items = overview.todayHabitItems;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('HÁBITOS DE HOY'),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'Completa hábitos para verlos aquí.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(
                      item.isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: item.isDone
                          ? const Color(0xFF55C8FF)
                          : const Color(0xFF4E4D73),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (item.xpReward > 0) ...[
                      const SizedBox(width: 10),
                      _SmallXp(xp: item.xpReward),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String subLabel;
  final Color color;

  const _MiniCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.subLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            subLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF181827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _SmallXp extends StatelessWidget {
  final int xp;

  const _SmallXp({required this.xp});

  @override
  Widget build(BuildContext context) {
    if (xp <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF163047),
      ),
      child: Text(
        '+$xp XP',
        style: const TextStyle(
          color: Color(0xFF55C8FF),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _Tappable extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _Tappable({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

IconData _iconFor(String key) {
  switch (key) {
    case 'training':
      return Icons.fitness_center;
    case 'nutrition':
      return Icons.restaurant;
    case 'recovery':
      return Icons.bedtime_outlined;
    case 'appearance':
      return Icons.auto_awesome;
    case 'discipline':
      return Icons.psychology_alt_outlined;
    case 'habit':
      return Icons.check_circle_outline;
    default:
      return Icons.bolt_outlined;
  }
}
