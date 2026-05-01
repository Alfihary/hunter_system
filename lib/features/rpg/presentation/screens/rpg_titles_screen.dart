import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/hunter_panel.dart';
import '../../../../shared/presentation/widgets/hunter_section_label.dart';
import '../../domain/rpg_title.dart';
import '../providers/rpg_controller.dart';

/// Pantalla de títulos RPG.
///
/// ¿Qué hace?
/// Lista todos los títulos disponibles:
/// - equipados
/// - desbloqueados
/// - bloqueados
///
/// ¿Para qué sirve?
/// Para que el usuario pueda elegir su identidad visual RPG.
class RpgTitlesScreen extends ConsumerWidget {
  const RpgTitlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titlesAsync = ref.watch(rpgTitlesProvider);
    final actionState = ref.watch(rpgActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Títulos RPG')),
      body: titlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (titles) {
          if (titles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay títulos disponibles todavía.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final unlockedCount = titles
              .where((title) => title.isUnlocked)
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rpgTitlesProvider);
              ref.invalidate(rpgControllerProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TitlesHeader(
                  totalTitles: titles.length,
                  unlockedTitles: unlockedCount,
                ),
                const SizedBox(height: 16),
                const HunterSectionLabel('COLECCIÓN DE TÍTULOS'),
                const SizedBox(height: 12),
                ...titles.map(
                  (title) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TitleCard(
                      title: title,
                      isBusy: actionState.isLoading,
                      onEquip: () async {
                        final error = await ref
                            .read(rpgActionControllerProvider.notifier)
                            .equipTitle(title.id);

                        if (!context.mounted) return;

                        if (error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Título equipado: ${title.name}'),
                          ),
                        );
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

/// Header superior de progreso de títulos.
class _TitlesHeader extends StatelessWidget {
  final int totalTitles;
  final int unlockedTitles;

  const _TitlesHeader({
    required this.totalTitles,
    required this.unlockedTitles,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTitles <= 0 ? 0.0 : unlockedTitles / totalTitles;

    return HunterPanel(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HunterSectionLabel('IDENTIDAD RPG'),
          const SizedBox(height: 8),
          Text(
            '$unlockedTitles / $totalTitles títulos desbloqueados',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(
            'Equipa un título para mostrarlo en tu perfil y dashboard.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Card visual de un título RPG.
class _TitleCard extends StatelessWidget {
  final RpgTitle title;
  final bool isBusy;
  final Future<void> Function() onEquip;

  const _TitleCard({
    required this.title,
    required this.isBusy,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final icon = title.isEquipped
        ? Icons.workspace_premium
        : title.isUnlocked
        ? Icons.auto_awesome
        : Icons.lock_outline;

    final color = title.isEquipped
        ? scheme.primary
        : title.isUnlocked
        ? scheme.secondary
        : scheme.outline;

    return HunterPanel(
      highlighted: title.isEquipped,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusBadge(title: title),
            ],
          ),
          const SizedBox(height: 12),
          Text(title.description),
          const SizedBox(height: 10),
          Text(
            'Requisito: ${title.requirementText}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (!title.canEquip || isBusy) ? null : onEquip,
              icon: Icon(title.isEquipped ? Icons.check : Icons.emoji_events),
              label: Text(
                title.isEquipped
                    ? 'Título equipado'
                    : title.isUnlocked
                    ? 'Equipar título'
                    : 'Bloqueado',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge del estado actual del título.
class _StatusBadge extends StatelessWidget {
  final RpgTitle title;

  const _StatusBadge({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final color = title.isEquipped
        ? scheme.primary
        : title.isUnlocked
        ? scheme.secondary
        : scheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        title.statusLabel,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
