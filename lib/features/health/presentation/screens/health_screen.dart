import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/health_overview.dart';
import '../../domain/sleep_day_summary.dart';
import '../providers/health_controller.dart';

/// Pantalla principal del módulo Health.
///
/// ¿Qué hace?
/// Muestra:
/// - pasos del día
/// - sueño reciente
/// - estado de permisos
///
/// ¿Para qué sirve?
/// Para centralizar datos automáticos medidos por Health Connect / HealthKit.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(healthControllerProvider);
    final actionState = ref.watch(healthActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              ref.read(healthControllerProvider.notifier).reload();
            },
            icon: const Icon(Icons.refresh),
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
          if (!overview.isSupportedPlatform) {
            return const _UnsupportedPlatformView();
          }

          if (!overview.hasPermissions) {
            return _PermissionsView(
              isBusy: actionState.isLoading,
              onRequestPermissions: () async {
                final error = await ref
                    .read(healthActionControllerProvider.notifier)
                    .requestPermissions();

                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                }
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(healthControllerProvider.notifier).reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HealthHeader(overview: overview),
                const SizedBox(height: 12),
                _StepsCard(overview: overview),
                const SizedBox(height: 12),
                _SleepCard(sleep: overview.sleep),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UnsupportedPlatformView extends StatelessWidget {
  const _UnsupportedPlatformView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Este módulo sólo está disponible en Android e iPhone.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PermissionsView extends StatelessWidget {
  final bool isBusy;
  final Future<void> Function() onRequestPermissions;

  const _PermissionsView({
    required this.isBusy,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_outline, size: 44),
                const SizedBox(height: 12),
                Text(
                  'Conecta tu salud',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Necesitas autorizar pasos y sueño para ver tu actividad automática.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: isBusy ? null : onRequestPermissions,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: const Text('Conectar permisos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthHeader extends StatelessWidget {
  final HealthOverview overview;

  const _HealthHeader({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              child: Icon(Icons.health_and_safety_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actividad automática',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha: ${overview.date.day}/${overview.date.month}/${overview.date.year}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final HealthOverview overview;

  const _StepsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final steps = overview.steps;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.directions_walk),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pasos de hoy',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (steps.goalReached)
                  const _StatusBadge(label: 'Meta cumplida'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${steps.steps}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: steps.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              '${steps.steps} / ${steps.goalSteps} pasos',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Restantes: ${steps.remainingSteps}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  final SleepDaySummary sleep;

  const _SleepCard({required this.sleep});

  @override
  Widget build(BuildContext context) {
    if (!sleep.hasSleepData) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sueño reciente (24h)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'No encontré datos de sueño recientes.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sueño reciente (24h)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (sleep.goalReached) const _StatusBadge(label: 'Recovery OK'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${sleep.totalHours.toStringAsFixed(1)} h',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: sleep.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              '${sleep.totalMinutesAsleep} / ${sleep.goalSleepMinutes} min',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _SleepRow(label: 'Ligero', value: '${sleep.lightMinutes} min'),
            const SizedBox(height: 6),
            _SleepRow(label: 'Profundo', value: '${sleep.deepMinutes} min'),
            const SizedBox(height: 6),
            _SleepRow(label: 'REM', value: '${sleep.remMinutes} min'),
            const SizedBox(height: 6),
            _SleepRow(label: 'Despierto', value: '${sleep.awakeMinutes} min'),
            const SizedBox(height: 6),
            _SleepRow(
              label: 'Sesiones detectadas',
              value: '${sleep.sessionCount}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepRow extends StatelessWidget {
  final String label;
  final String value;

  const _SleepRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Text(label),
    );
  }
}
