import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/hunter_panel.dart';
import '../../../../shared/presentation/widgets/hunter_section_label.dart';
import '../../../../shared/presentation/widgets/hunter_tappable.dart';
import '../../../../shared/providers/theme_provider.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../health/presentation/providers/health_controller.dart';
import '../../../profile/domain/hunter_profile_overview.dart';
import '../providers/hunter_profile_controller.dart';
import '../../../quests/presentation/providers/daily_mission_controller.dart';
import '../../../rpg/presentation/providers/rpg_controller.dart';
import '../../../../app/theme/app_theme_preset.dart';

/// Pantalla de perfil del cazador.
///
/// ¿Qué hace?
/// Muestra información del usuario, configuración de tema,
/// accesos rápidos y opciones de seguridad.
///
/// ¿Para qué sirve?
/// Centralizar la configuración y progreso del usuario.
class HunterProfileScreen extends ConsumerWidget {
  const HunterProfileScreen({super.key});

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
                _ProfileHeader(
                  name: user?.name ?? 'Jugador',
                  email: user?.email ?? 'Sin correo',
                  overview: overview,
                ),
                const SizedBox(height: 16),

                _ThemeSection(
                  themeState: themeState,
                  controller: themeController,
                ),
                const SizedBox(height: 16),

                const _QuickAccessSection(),
                const SizedBox(height: 16),

                const _SecuritySection(),
                const SizedBox(height: 16),

                const _LogoutSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ================= HEADER =================

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final HunterProfileOverview overview;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('CAZADOR'),
          const SizedBox(height: 8),

          Text(name, style: Theme.of(context).textTheme.headlineSmall),

          const SizedBox(height: 4),
          Text(email),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: Text('Nivel ${overview.level}')),
              Expanded(child: Text('${overview.totalXp} XP')),
            ],
          ),
        ],
      ),
    );
  }
}

/// ================= THEME =================

class _ThemeSection extends StatelessWidget {
  final AppThemeState themeState;
  final ThemeController controller;

  const _ThemeSection({required this.themeState, required this.controller});

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('APARIENCIA'),
          const SizedBox(height: 12),

          SwitchListTile(
            value: themeState.mode == ThemeMode.dark,
            onChanged: (_) => controller.toggleThemeMode(),
            title: const Text('Modo oscuro'),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<AppThemePreset>(
            initialValue: themeState.preset,
            items: AppThemePreset.values.map((preset) {
              return DropdownMenuItem(value: preset, child: Text(preset.label));
            }).toList(),
            onChanged: (preset) {
              if (preset != null) {
                controller.setPreset(preset);
              }
            },
            decoration: const InputDecoration(labelText: 'Tema RPG'),
          ),
        ],
      ),
    );
  }
}

/// ================= QUICK ACCESS =================

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection();

  @override
  Widget build(BuildContext context) {
    return HunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('ACCESOS RÁPIDOS'),
          const SizedBox(height: 12),

          _NavTile(icon: Icons.auto_graph, label: 'Stats', route: '/stats'),
          _NavTile(icon: Icons.flag, label: 'Misiones', route: '/missions'),
          _NavTile(icon: Icons.favorite, label: 'Health', route: '/health'),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return HunterTappable(
      onTap: () => context.push(route),
      child: ListTile(leading: Icon(icon), title: Text(label)),
    );
  }
}

/// ================= SECURITY =================

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('SEGURIDAD'),
          const SizedBox(height: 12),

          HunterTappable(
            onTap: () => _showChangePasswordDialog(context, ref),
            child: const ListTile(
              leading: Icon(Icons.lock),
              title: Text('Cambiar contraseña'),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final current = TextEditingController();
    final next = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              decoration: const InputDecoration(labelText: 'Actual'),
              obscureText: true,
            ),
            TextField(
              controller: next,
              decoration: const InputDecoration(labelText: 'Nueva'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await ref
                  .read(authControllerProvider.notifier)
                  .changePassword(
                    currentPassword: current.text,
                    newPassword: next.text,
                  );

              if (context.mounted) Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Contraseña actualizada'
                        : 'Error al actualizar contraseña',
                  ),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

/// ================= LOGOUT =================

class _LogoutSection extends ConsumerWidget {
  const _LogoutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HunterPanel(
      child: HunterTappable(
        onTap: () async {
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
        child: const ListTile(
          leading: Icon(Icons.logout),
          title: Text('Cerrar sesión'),
        ),
      ),
    );
  }
}
