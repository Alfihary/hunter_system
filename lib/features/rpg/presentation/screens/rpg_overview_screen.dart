import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/rpg_overview.dart';
import '../../domain/rpg_rank.dart';
import '../../domain/rpg_stats.dart';
import '../../domain/rpg_title.dart';
import '../providers/rpg_controller.dart';

/// Pantalla principal del sistema RPG.
///
/// ¿Qué hace?
/// Muestra:
/// - rango
/// - nivel
/// - XP total
/// - progreso al siguiente nivel
/// - progreso al siguiente rango
/// - racha global
/// - desglose de XP por módulo
/// - stats del personaje
/// - título equipado
///
/// ¿Para qué sirve?
/// Para convertir la actividad real del usuario
/// en progreso visible tipo videojuego.
class RpgOverviewScreen extends ConsumerWidget {
  const RpgOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(rpgControllerProvider);
    final titlesAsync = ref.watch(rpgTitlesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hunter RPG')),
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
              await ref.read(rpgControllerProvider.notifier).reload();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (equippedTitle != null) ...[
                  _EquippedTitleCard(title: equippedTitle),
                  const SizedBox(height: 12),
                ],
                const _QuickActionsCard(),
                const SizedBox(height: 12),
                _RankCard(overview: overview),
                const SizedBox(height: 12),
                _LevelCard(overview: overview),
                const SizedBox(height: 12),
                _BreakdownCard(overview: overview),
                const SizedBox(height: 12),
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

class _EquippedTitleCard extends StatelessWidget {
  final RpgTitle title;

  const _EquippedTitleCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              'TÍTULO EQUIPADO',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              title.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(title.description, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => context.push('/missions'),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Misiones'),
            ),
            FilledButton.icon(
              onPressed: () => context.push('/rpg/achievements'),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Logros'),
            ),
            FilledButton.icon(
              onPressed: () => context.push('/rpg/titles'),
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('Títulos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final RpgOverview overview;

  const _RankCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final rankColor = _colorForRank(overview.rank);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text('RANGO ACTUAL', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              overview.rank.label,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: rankColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (overview.nextRank != null) ...[
              LinearProgressIndicator(
                value: overview.rankProgress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 8),
              Text(
                '${overview.xpIntoCurrentRank} / ${overview.xpForNextRank} XP para rango ${overview.nextRank!.label}',
                textAlign: TextAlign.center,
              ),
            ] else
              const Text(
                'Has alcanzado el rango máximo actual.',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Color _colorForRank(RpgRank rank) {
    switch (rank) {
      case RpgRank.e:
        return Colors.grey;
      case RpgRank.d:
        return Colors.green;
      case RpgRank.c:
        return Colors.lightBlue;
      case RpgRank.b:
        return Colors.blue;
      case RpgRank.a:
        return Colors.purple;
      case RpgRank.s:
        return Colors.orange;
      case RpgRank.ss:
        return Colors.deepOrange;
      case RpgRank.sssPlus:
        return Colors.red;
    }
  }
}

class _LevelCard extends StatelessWidget {
  final RpgOverview overview;

  const _LevelCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Nivel ${overview.level}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('XP total: ${overview.totalXp}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: overview.levelProgress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              '${overview.xpIntoCurrentLevel} / ${overview.xpForNextLevel} XP para el siguiente nivel',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(
                'Racha global: ${overview.activeStreakDays} día(s)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final RpgOverview overview;

  const _BreakdownCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'XP por módulo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _XpRow(label: 'Hábitos', value: overview.breakdown.habitsXp),
            const SizedBox(height: 8),
            _XpRow(
              label: 'Entrenamiento',
              value: overview.breakdown.workoutsXp,
            ),
            const SizedBox(height: 8),
            _XpRow(label: 'Nutrición', value: overview.breakdown.nutritionXp),
            const SizedBox(height: 8),
            _XpRow(label: 'Health', value: overview.breakdown.healthXp),
            const SizedBox(height: 8),
            _XpRow(label: 'Misiones', value: overview.breakdown.questsXp),
          ],
        ),
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
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text('$value XP'),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final RpgStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxScale = stats.maxValue < 100 ? 100 : stats.maxValue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Stats del personaje',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: 'Strength',
              value: stats.strength,
              maxScale: maxScale,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Endurance',
              value: stats.endurance,
              maxScale: maxScale,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Discipline',
              value: stats.discipline,
              maxScale: maxScale,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Recovery',
              value: stats.recovery,
              maxScale: maxScale,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Balance',
              value: stats.balance,
              maxScale: maxScale,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Consistency',
              value: stats.consistency,
              maxScale: maxScale,
            ),
          ],
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}
