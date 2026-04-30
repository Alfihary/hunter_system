import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/stats/domain/rpg_stats_analysis.dart';
import '../../../../features/stats/domain/weekly_training_volume.dart';
import '../../../../features/stats/presentation/providers/training_stats_controller.dart';
import '../../../../features/stats/presentation/widgets/rpg_stats_radar_chart.dart';
import '../../../../features/stats/presentation/widgets/weekly_training_volume_chart.dart';
import '../../../../shared/presentation/widgets/hunter_rank_badge.dart';
import '../../../../shared/presentation/widgets/hunter_surface_card.dart';
import '../../domain/rpg_overview.dart';
import '../../domain/rpg_stats.dart';
import '../../domain/rpg_title.dart';
import '../providers/rpg_controller.dart';

/// Pantalla STATS del cazador.
///
/// ¿Qué hace?
/// Muestra progreso real:
/// - rango, nivel, XP y racha
/// - volumen semanal de entrenamiento
/// - análisis automático del volumen
/// - radar RPG de atributos
/// - análisis inteligente de atributos
/// - fuentes de XP
/// - atributos numéricos
///
/// ¿Para qué sirve?
/// Para que el usuario entienda su progreso como si fuera un panel RPG real.
class RpgOverviewScreen extends ConsumerWidget {
  const RpgOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(rpgControllerProvider);
    final titlesAsync = ref.watch(rpgTitlesProvider);
    final volumeAsync = ref.watch(weeklyTrainingVolumeProvider);
    final volumeAnalysisAsync = ref.watch(weeklyTrainingVolumeAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          IconButton(
            tooltip: 'Logros',
            onPressed: () => context.push('/rpg/achievements'),
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
          IconButton(
            tooltip: 'Títulos',
            onPressed: () => context.push('/rpg/titles'),
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (overview) {
          final equippedTitle = _findEquippedTitle(titlesAsync.asData?.value);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rpgTitlesProvider);
              ref.invalidate(rpgAchievementsProvider);
              ref.invalidate(weeklyTrainingVolumeProvider);
              ref.invalidate(weeklyTrainingVolumeAnalysisProvider);
              await ref.read(rpgControllerProvider.notifier).reload();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'ESTADÍSTICAS DEL CAZADOR',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu progreso real',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                _RankHeroCard(overview: overview, title: equippedTitle),
                const SizedBox(height: 14),
                _QuickStatsGrid(overview: overview),
                const SizedBox(height: 14),
                _TrainingVolumeCard(
                  volumeAsync: volumeAsync,
                  analysisAsync: volumeAnalysisAsync,
                ),
                const SizedBox(height: 14),
                _RpgRadarCard(stats: overview.stats),
                const SizedBox(height: 14),
                _RpgStatsAnalysisCard(stats: overview.stats),
                const SizedBox(height: 14),
                _XpBreakdownCard(overview: overview),
                const SizedBox(height: 14),
                _StatsCard(stats: overview.stats),
              ],
            ),
          );
        },
      ),
    );
  }

  RpgTitle? _findEquippedTitle(List<RpgTitle>? titles) {
    if (titles == null) return null;

    for (final title in titles) {
      if (title.isEquipped) return title;
    }

    return null;
  }
}

/// Card principal del rango actual.
class _RankHeroCard extends StatelessWidget {
  final RpgOverview overview;
  final RpgTitle? title;

  const _RankHeroCard({required this.overview, required this.title});

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      highlighted: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RankBox(rank: overview.rank.label),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HunterRankBadge(
                      rankLabel: overview.rank.label,
                      compact: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${overview.totalXp} XP acumulados',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (title != null) ...[
                      const SizedBox(height: 6),
                      Text(title!.name),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: overview.nextRank == null ? 1 : overview.rankProgress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(
            overview.nextRank == null
                ? 'Rango máximo alcanzado'
                : '${overview.xpIntoCurrentRank} / ${overview.xpForNextRank} XP para rango ${overview.nextRank!.label}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Caja visual del rango.
class _RankBox extends StatelessWidget {
  final String rank;

  const _RankBox({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        rank,
        style: Theme.of(
          context,
        ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// Métricas rápidas superiores.
class _QuickStatsGrid extends StatelessWidget {
  final RpgOverview overview;

  const _QuickStatsGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.trending_up_outlined,
            value: '${overview.level}',
            label: 'Nivel',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.local_fire_department_outlined,
            value: '${overview.activeStreakDays}',
            label: 'Racha',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.bolt_outlined,
            value: '${overview.totalXp}',
            label: 'XP',
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

/// Card de gráfica de volumen semanal.
class _TrainingVolumeCard extends StatelessWidget {
  final AsyncValue<List<WeeklyTrainingVolume>> volumeAsync;
  final AsyncValue<WeeklyTrainingVolumeAnalysis> analysisAsync;

  const _TrainingVolumeCard({
    required this.volumeAsync,
    required this.analysisAsync,
  });

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOLUMEN SEMANAL',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Reps × peso por semana',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          volumeAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SizedBox(
              height: 180,
              child: Center(
                child: Text(error.toString(), textAlign: TextAlign.center),
              ),
            ),
            data: (data) => WeeklyTrainingVolumeChart(data: data),
          ),
          const SizedBox(height: 14),
          analysisAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            data: (analysis) => _VolumeAnalysisPanel(analysis: analysis),
          ),
        ],
      ),
    );
  }
}

/// Panel inteligente del análisis de volumen.
class _VolumeAnalysisPanel extends StatelessWidget {
  final WeeklyTrainingVolumeAnalysis analysis;

  const _VolumeAnalysisPanel({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final icon = switch (analysis.trend) {
      WeeklyVolumeTrend.increased => Icons.trending_up,
      WeeklyVolumeTrend.decreased => Icons.trending_down,
      WeeklyVolumeTrend.maintained => Icons.trending_flat,
      WeeklyVolumeTrend.firstData => Icons.flag_outlined,
      WeeklyVolumeTrend.noData => Icons.info_outline,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.message,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de radar RPG.
class _RpgRadarCard extends StatelessWidget {
  final RpgStats stats;

  const _RpgRadarCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RADAR RPG', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            'Distribución visual de tus atributos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          RpgStatsRadarChart(stats: stats),
        ],
      ),
    );
  }
}

/// Card de análisis inteligente del radar RPG.
class _RpgStatsAnalysisCard extends StatelessWidget {
  final RpgStats stats;

  const _RpgStatsAnalysisCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final analysis = RpgStatsAnalyzer.analyze(stats);

    return HunterSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANÁLISIS RPG', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            'Interpretación de tus atributos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                analysis.isBalanced
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  analysis.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(analysis.message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _XpBreakdownCard extends StatelessWidget {
  final RpgOverview overview;

  const _XpBreakdownCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return HunterSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FUENTES DE XP', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          _XpRow(label: 'Hábitos', value: overview.breakdown.habitsXp),
          _XpRow(label: 'Entrenamiento', value: overview.breakdown.workoutsXp),
          _XpRow(label: 'Dieta', value: overview.breakdown.nutritionXp),
          _XpRow(label: 'Health', value: overview.breakdown.healthXp),
          _XpRow(label: 'Misiones', value: overview.breakdown.questsXp),
        ],
      ),
    );
  }
}

class _XpRow extends StatelessWidget {
  final String label;
  final int value;

  const _XpRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value XP'),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final RpgStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxScale = stats.maxValue < 100 ? 100 : stats.maxValue;

    return HunterSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ATRIBUTOS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          _StatRow(
            label: 'Strength',
            value: stats.strength,
            maxScale: maxScale,
          ),
          _StatRow(
            label: 'Endurance',
            value: stats.endurance,
            maxScale: maxScale,
          ),
          _StatRow(
            label: 'Discipline',
            value: stats.discipline,
            maxScale: maxScale,
          ),
          _StatRow(
            label: 'Recovery',
            value: stats.recovery,
            maxScale: maxScale,
          ),
          _StatRow(label: 'Balance', value: stats.balance, maxScale: maxScale),
          _StatRow(
            label: 'Consistency',
            value: stats.consistency,
            maxScale: maxScale,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxScale;

  const _StatRow({
    required this.label,
    required this.value,
    required this.maxScale,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxScale <= 0 ? 0.0 : (value / maxScale).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: $value'),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}
