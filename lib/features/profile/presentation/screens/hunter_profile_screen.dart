import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme_preset.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../features/health/presentation/providers/health_controller.dart';
import '../../../../features/profile/domain/hunter_profile_overview.dart';
import '../../../../features/profile/presentation/providers/hunter_profile_controller.dart';
import '../../../../features/quests/presentation/providers/daily_mission_controller.dart';
import '../../../../features/rpg/domain/rpg_stats.dart';
import '../../../../features/rpg/presentation/providers/rpg_controller.dart';
import '../../../../shared/providers/theme_provider.dart';

/// Pantalla del perfil del cazador.
///
/// ¿Qué hace?
/// Muestra identidad, progreso, seguridad, configuración,
/// selector de tema RPG, health, stats, logros y registros globales.
class HunterProfileScreen extends ConsumerWidget {
  const HunterProfileScreen({super.key});

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                    helperText: 'Mínimo 8 caracteres, una letra y un número.',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final currentPassword = currentController.text.trim();
                final newPassword = newController.text.trim();
                final confirmPassword = confirmController.text.trim();

                if (currentPassword.isEmpty ||
                    newPassword.isEmpty ||
                    confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos.')),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Las contraseñas no coinciden.')),
                  );
                  return;
                }

                final success = await ref
                    .read(authControllerProvider.notifier)
                    .changePassword(
                      currentPassword: currentPassword,
                      newPassword: newPassword,
                    );

                if (!context.mounted) return;

                if (success) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada correctamente.'),
                    ),
                  );
                } else {
                  final error = ref.read(authControllerProvider).errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error ?? 'No se pudo cambiar la contraseña.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final overviewAsync = ref.watch(hunterProfileControllerProvider);
    final themeState = ref.watch(themeProvider);
    final themeController = ref.read(themeProvider.notifier);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del cazador')),
      body: overviewAsync.when(
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
              ref.invalidate(healthControllerProvider);
              ref.invalidate(todayDailyMissionsProvider);
              ref.invalidate(currentWeekQuestOverviewProvider);
              ref.invalidate(rpgControllerProvider);
              ref.invalidate(rpgAchievementsProvider);
              ref.invalidate(rpgTitlesProvider);
              await ref.read(hunterProfileControllerProvider.notifier).reload();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileHeroCard(
                  playerName: user?.name ?? 'Jugador',
                  email: user?.email ?? 'Sin correo',
                  overview: overview,
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  isDarkMode: themeState.isDarkMode,
                  selectedPreset: themeState.preset,
                  onToggleTheme: (_) => themeController.toggleThemeMode(),
                  onSelectPreset: themeController.setPreset,
                  onChangePassword: () {
                    _showChangePasswordDialog(context, ref);
                  },
                  onLogout: () async {
                    await ref.read(authControllerProvider.notifier).logout();

                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
                const SizedBox(height: 12),
                const _QuickActionsCard(),
                const SizedBox(height: 12),
                _WeeklyBoardCard(overview: overview),
                const SizedBox(height: 12),
                _HealthProfileCard(overview: overview),
                const SizedBox(height: 12),
                _StatsCard(stats: overview.stats),
                const SizedBox(height: 12),
                _AchievementsCard(overview: overview),
                const SizedBox(height: 12),
                _RecordsCard(overview: overview),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDarkMode;
  final AppThemePreset selectedPreset;
  final ValueChanged<bool> onToggleTheme;
  final ValueChanged<AppThemePreset> onSelectPreset;
  final VoidCallback onChangePassword;
  final Future<void> Function() onLogout;

  const _SettingsCard({
    required this.isDarkMode,
    required this.selectedPreset,
    required this.onToggleTheme,
    required this.onSelectPreset,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              'Configuración',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: isDarkMode,
              onChanged: onToggleTheme,
              title: const Text('Modo oscuro'),
              subtitle: const Text('Tema visual de la aplicación'),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tema RPG',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 10),
            ...AppThemePreset.values.map(
              (preset) => RadioListTile<AppThemePreset>(
                value: preset,
                groupValue: selectedPreset,
                onChanged: (value) {
                  if (value != null) {
                    onSelectPreset(value);
                  }
                },
                title: Text(preset.label),
                subtitle: Text(preset.description),
                secondary: Icon(Icons.circle, color: preset.primaryColor),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Cambiar contraseña'),
              subtitle: const Text('Actualiza tu acceso local'),
              onTap: onChangePassword,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final String playerName;
  final String email;
  final HunterProfileOverview overview;

  const _ProfileHeroCard({
    required this.playerName,
    required this.email,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.shield_moon_outlined),
            ),
            const SizedBox(height: 12),
            Text(
              playerName,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(email, textAlign: TextAlign.center),
            if (overview.hasEquippedTitle) ...[
              const SizedBox(height: 12),
              Text(
                overview.equippedTitleName!,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (overview.equippedTitleDescription != null) ...[
                const SizedBox(height: 6),
                Text(
                  overview.equippedTitleDescription!,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _ProfileBadge(label: 'Rango ${overview.rankLabel}'),
                _ProfileBadge(label: 'Nivel ${overview.level}'),
                _ProfileBadge(label: '${overview.totalXp} XP'),
                _ProfileBadge(label: 'Racha ${overview.activeStreakDays}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;

  const _ProfileBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Text(label),
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
              onPressed: () => context.push('/stats'),
              icon: const Icon(Icons.auto_graph_outlined),
              label: const Text('Stats'),
            ),
            FilledButton.icon(
              onPressed: () => context.push('/missions'),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Misiones'),
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
      ),
    );
  }
}

class _WeeklyBoardCard extends StatelessWidget {
  final HunterProfileOverview overview;

  const _WeeklyBoardCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Cadena semanal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: overview.weekProgress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Text(
              '${overview.weekClaims} / ${overview.weekMaxClaims} quests reclamadas',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Días activos: ${overview.weekActiveDays}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Días con tablero completo: ${overview.weekFullBoardDays}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthProfileCard extends StatelessWidget {
  final HunterProfileOverview overview;

  const _HealthProfileCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final supported = overview.isHealthSupported;
    final permissions = overview.hasHealthPermissions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Recovery y Health',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (!supported)
              const Text(
                'Health no está disponible en esta plataforma.',
                textAlign: TextAlign.center,
              )
            else if (!permissions)
              const Text(
                'Health está disponible, pero faltan permisos.',
                textAlign: TextAlign.center,
              )
            else ...[
              _MetricProgressRow(
                label: 'Pasos',
                value: '${overview.stepsToday}',
                subtitle: '${overview.stepsToday} / ${overview.stepGoal}',
                progress: overview.stepsProgress,
              ),
              const SizedBox(height: 12),
              _MetricProgressRow(
                label: 'Sueño',
                value: '${overview.sleepHours.toStringAsFixed(1)} h',
                subtitle:
                    '${overview.sleepMinutesToday} / ${overview.sleepGoalMinutes} min',
                progress: overview.sleepProgress,
              ),
            ],
          ],
        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Stats del cazador',
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

class _AchievementsCard extends StatelessWidget {
  final HunterProfileOverview overview;

  const _AchievementsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Logros destacados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '${overview.unlockedAchievements} / ${overview.totalAchievements} desbloqueados',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (overview.featuredAchievementNames.isEmpty)
              const Text(
                'Todavía no hay logros desbloqueados para destacar.',
                textAlign: TextAlign.center,
              )
            else
              ...overview.featuredAchievementNames.map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_outlined),
                      const SizedBox(width: 8),
                      Expanded(child: Text(name)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordsCard extends StatelessWidget {
  final HunterProfileOverview overview;

  const _RecordsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Registros globales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _RecordRow(
              label: 'Hábitos creados',
              value: '${overview.habitsCount}',
            ),
            const SizedBox(height: 6),
            _RecordRow(
              label: 'Registros de hábitos',
              value: '${overview.habitLogsCount}',
            ),
            const SizedBox(height: 6),
            _RecordRow(label: 'Rutinas', value: '${overview.routineCount}'),
            const SizedBox(height: 6),
            _RecordRow(
              label: 'Entrenamientos finalizados',
              value: '${overview.finishedWorkoutsCount}',
            ),
            const SizedBox(height: 6),
            _RecordRow(
              label: 'Logs de nutrición',
              value: '${overview.nutritionLogsCount}',
            ),
            const SizedBox(height: 6),
            _RecordRow(
              label: 'Claims diarios',
              value: '${overview.dailyMissionClaimsCount}',
            ),
            const SizedBox(height: 6),
            _RecordRow(
              label: 'Rewards semanales',
              value: '${overview.weeklyRewardClaimsCount}',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final double progress;

  const _MetricProgressRow({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
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

class _RecordRow extends StatelessWidget {
  final String label;
  final String value;

  const _RecordRow({required this.label, required this.value});

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