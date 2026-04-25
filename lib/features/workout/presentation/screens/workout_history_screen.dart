import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/workout_controller.dart';

/// Pantalla de historial de entrenamientos.
///
/// ¿Qué hace?
/// Muestra todas las sesiones terminadas ordenadas por fecha.
///
/// ¿Para qué sirve?
/// Para que el usuario pueda revisar entrenamientos pasados,
/// medir constancia y abrir el detalle de cualquier sesión.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(completedWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(completedWorkoutsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyHistoryView();
          }

          final totalSets = items.fold<int>(
            0,
            (sum, item) => sum + item.totalSets,
          );

          final totalMinutes = items.fold<int>(
            0,
            (sum, item) => sum + item.duration.inMinutes,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(completedWorkoutsProvider);
              await ref.read(completedWorkoutsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(
                  sessions: items.length,
                  totalSets: totalSets,
                  totalMinutes: totalMinutes,
                ),
                const SizedBox(height: 18),
                const _SectionLabel('SESIONES TERMINADAS'),
                const SizedBox(height: 12),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HistoryCard(
                      routineName: item.routineName,
                      endedAt: item.endedAt,
                      totalSets: item.totalSets,
                      duration: item.duration,
                      onTap: () {
                        context.push('/workouts/history/${item.workoutId}');
                      },
                    ),
                  ),
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
  final int sessions;
  final int totalSets;
  final int totalMinutes;

  const _Header({
    required this.sessions,
    required this.totalSets,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('REGISTRO DE BATALLAS'),
          const SizedBox(height: 8),
          Text(
            'Historial de entrenamiento',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.fitness_center,
                  value: '$sessions',
                  label: 'Sesiones',
                  color: const Color(0xFF55C8FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.bolt_outlined,
                  value: '$totalSets',
                  label: 'Sets',
                  color: const Color(0xFF8C7CFF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.timer_outlined,
                  value: '${totalMinutes}m',
                  label: 'Tiempo',
                  color: const Color(0xFFFFD93D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String routineName;
  final DateTime endedAt;
  final int totalSets;
  final Duration duration;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.routineName,
    required this.endedAt,
    required this.totalSets,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: _Panel(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF121827),
                border: Border.all(
                  color: const Color(0xFF55C8FF).withOpacity(0.20),
                ),
              ),
              child: const Icon(Icons.fitness_center, color: Color(0xFF55C8FF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routineName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(endedAt)} • $totalSets sets • ${_formatDuration(duration)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, size: 52),
              const SizedBox(height: 14),
              Text(
                'Sin sesiones terminadas',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Finaliza un entrenamiento para que aparezca aquí tu registro de batallas.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'No se pudo cargar el historial',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF1D2033) : const Color(0xFF181827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF55C8FF).withOpacity(0.20)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: child,
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
