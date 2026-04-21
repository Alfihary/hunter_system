import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/rpg_title.dart';
import '../providers/rpg_controller.dart';

/// Pantalla de títulos RPG.
///
/// ¿Qué hace?
/// Lista todos los títulos del personaje, mostrando:
/// - si están desbloqueados
/// - si están equipados
/// - requisito
/// - acción para equipar
///
/// ¿Para qué sirve?
/// Para que el usuario elija la identidad visual de su personaje.
class RpgTitlesScreen extends ConsumerWidget {
  const RpgTitlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titlesAsync = ref.watch(rpgTitlesProvider);
    final actionState = ref.watch(rpgActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Títulos')),
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
            return const Center(child: Text('No hay títulos disponibles.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: titles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final title = titles[index];

              return _TitleCard(
                title: title,
                isBusy: actionState.isLoading,
                onEquip: () async {
                  final error = await ref
                      .read(rpgActionControllerProvider.notifier)
                      .equipTitle(title.id);

                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

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
    final unlockedColor = title.isUnlocked
        ? Colors.green
        : Theme.of(context).colorScheme.outline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  title.isUnlocked ? Icons.auto_awesome : Icons.lock_outline,
                  color: unlockedColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (title.isEquipped)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: const Text('Equipado'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title.description),
            const SizedBox(height: 8),
            Text(
              'Requisito: ${title.requirementText}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (!title.isUnlocked || title.isEquipped || isBusy)
                    ? null
                    : onEquip,
                child: Text(
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
      ),
    );
  }
}
