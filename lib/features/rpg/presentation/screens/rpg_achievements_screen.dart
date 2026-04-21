import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/achievement.dart';
import '../../domain/achievement_rarity.dart';
import '../providers/rpg_controller.dart';

/// Pantalla de logros RPG.
///
/// ¿Qué hace?
/// Lista todos los logros del personaje, mostrando:
/// - estado desbloqueado
/// - progreso
/// - rareza
///
/// ¿Para qué sirve?
/// Para que el usuario vea metas cumplidas y objetivos pendientes.
class RpgAchievementsScreen extends ConsumerWidget {
  const RpgAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(rpgAchievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (achievements) {
          if (achievements.isEmpty) {
            return const Center(child: Text('No hay logros disponibles.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _AchievementCard(achievement: achievement);
            },
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final rarityColor = _colorForRarity(achievement.rarity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  achievement.isUnlocked ? Icons.verified : Icons.lock_outline,
                  color: achievement.isUnlocked ? Colors.green : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    achievement.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: rarityColor.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    achievement.rarity.label,
                    style: TextStyle(
                      color: rarityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(achievement.description),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: achievement.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              '${achievement.clampedProgress} / ${achievement.targetProgress}',
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForRarity(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
      case AchievementRarity.mythic:
        return Colors.red;
    }
  }
}
