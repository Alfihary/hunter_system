import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/system_diagnostics_overview.dart';
import '../../domain/system_repair_result.dart';
import '../providers/system_diagnostics_controller.dart';
import '../providers/system_repair_controller.dart';

/// Pantalla de diagnóstico del sistema.
///
/// ¿Qué hace?
/// Muestra:
/// - resumen general
/// - estado por módulo
/// - conteos reales de datos
/// - acciones de reparación rápida
///
/// ¿Para qué sirve?
/// Para estabilizar el proyecto antes de seguir agregando features.
class SystemDiagnosticsScreen extends ConsumerWidget {
  const SystemDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(systemDiagnosticsOverviewProvider);
    final repairState = ref.watch(systemRepairControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico del sistema'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () async {
              ref.invalidate(systemDiagnosticsOverviewProvider);
              await ref.read(systemDiagnosticsOverviewProvider.future);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: diagnosticsAsync.when(
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
              ref.invalidate(systemDiagnosticsOverviewProvider);
              await ref.read(systemDiagnosticsOverviewProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RepairActionsCard(
                  isBusy: repairState.isLoading,
                  onEnsureBaseConfiguration: () async {
                    final result = await ref
                        .read(systemRepairControllerProvider.notifier)
                        .ensureBaseConfiguration();
                    _showRepairFeedback(context, result);
                  },
                  onSeedRecommendedHabits: () async {
                    final result = await ref
                        .read(systemRepairControllerProvider.notifier)
                        .seedRecommendedHabits();
                    _showRepairFeedback(context, result);
                  },
                  onSyncHealthNow: () async {
                    final result = await ref
                        .read(systemRepairControllerProvider.notifier)
                        .syncHealthNow();
                    _showRepairFeedback(context, result);
                  },
                ),
                const SizedBox(height: 12),
                _SummaryCard(overview: overview),
                const SizedBox(height: 12),
                _CountsCard(overview: overview),
                const SizedBox(height: 12),
                ...overview.checks.map((check) => _CheckCard(check: check)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Muestra el resultado de una reparación con feedback visual claro.
  void _showRepairFeedback(BuildContext context, SystemRepairResult result) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _RepairActionsCard extends StatelessWidget {
  final bool isBusy;
  final Future<void> Function() onEnsureBaseConfiguration;
  final Future<void> Function() onSeedRecommendedHabits;
  final Future<void> Function() onSyncHealthNow;

  const _RepairActionsCard({
    required this.isBusy,
    required this.onEnsureBaseConfiguration,
    required this.onSeedRecommendedHabits,
    required this.onSyncHealthNow,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Acciones rápidas de reparación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Estas acciones ayudan a corregir configuración faltante, sembrar hábitos clave y forzar sincronización de Health.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: isBusy ? null : onEnsureBaseConfiguration,
                  icon: const Icon(Icons.build_circle_outlined),
                  label: const Text('Reparar base'),
                ),
                FilledButton.icon(
                  onPressed: isBusy ? null : onSeedRecommendedHabits,
                  icon: const Icon(Icons.playlist_add_check_circle_outlined),
                  label: const Text('Crear hábitos recomendados'),
                ),
                FilledButton.icon(
                  onPressed: isBusy ? null : onSyncHealthNow,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Sincronizar Health'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SystemDiagnosticsOverview overview;

  const _SummaryCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final total = overview.checks.length;
    final ok = overview.okCount;
    final warnings = overview.warningCount;
    final errors = overview.errorCount;
    final progress = total <= 0 ? 0.0 : (ok / total).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Resumen general',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Text(
              'OK: $ok  |  Advertencias: $warnings  |  Errores: $errors',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Generado: '
              '${overview.generatedAt.day}/${overview.generatedAt.month}/${overview.generatedAt.year} '
              '${overview.generatedAt.hour.toString().padLeft(2, '0')}:'
              '${overview.generatedAt.minute.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountsCard extends StatelessWidget {
  final SystemDiagnosticsOverview overview;

  const _CountsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Conteos reales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _CountRow(label: 'Hábitos', value: '${overview.habitsCount}'),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Registros de hábitos',
              value: '${overview.habitLogsCount}',
            ),
            const SizedBox(height: 6),
            _CountRow(label: 'Rutinas', value: '${overview.routineCount}'),
            const SizedBox(height: 6),
            _CountRow(label: 'Sesiones', value: '${overview.workoutsCount}'),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Entrenamientos finalizados',
              value: '${overview.finishedWorkoutsCount}',
            ),
            const SizedBox(height: 6),
            _CountRow(label: 'Sets', value: '${overview.workoutSetsCount}'),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Logs de nutrición',
              value: '${overview.nutritionLogsCount}',
            ),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Meta nutricional base',
              value: overview.hasNutritionGoal ? 'Sí' : 'No',
            ),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Health soportado',
              value: overview.isHealthSupported ? 'Sí' : 'No',
            ),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Permisos Health',
              value: overview.hasHealthPermissions ? 'Sí' : 'No',
            ),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Snapshots Health',
              value: '${overview.healthSnapshotsCount}',
            ),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Último snapshot Health',
              value: overview.lastHealthSnapshotDateKey ?? 'Sin datos',
            ),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Claims diarios',
              value: '${overview.dailyMissionClaimsCount}',
            ),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Rewards semanales',
              value: '${overview.weeklyRewardClaimsCount}',
            ),
            const SizedBox(height: 6),
            _CountRow(
              label: 'Configuración RPG',
              value: overview.hasRpgProfileSettings ? 'Sí' : 'No',
            ),
          ],
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final String value;

  const _CountRow({required this.label, required this.value});

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

class _CheckCard extends StatelessWidget {
  final SystemDiagnosticCheck check;

  const _CheckCard({required this.check});

  @override
  Widget build(BuildContext context) {
    final color = _colorForSeverity(check.severity);
    final icon = _iconForSeverity(check.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    check.title,
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
                    color: color.withOpacity(0.12),
                  ),
                  child: Text(
                    check.severity.label,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(check.message),
            if (check.details != null) ...[
              const SizedBox(height: 8),
              Text(
                check.details!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorForSeverity(DiagnosticSeverity severity) {
    switch (severity) {
      case DiagnosticSeverity.ok:
        return Colors.green;
      case DiagnosticSeverity.warning:
        return Colors.orange;
      case DiagnosticSeverity.error:
        return Colors.red;
    }
  }

  IconData _iconForSeverity(DiagnosticSeverity severity) {
    switch (severity) {
      case DiagnosticSeverity.ok:
        return Icons.verified;
      case DiagnosticSeverity.warning:
        return Icons.warning_amber_rounded;
      case DiagnosticSeverity.error:
        return Icons.error_outline;
    }
  }
}
