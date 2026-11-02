import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/modes/mode_registry.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../profile/profile_controller.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  static String _duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = seconds % 3600 ~/ 60;
    return h > 0 ? '$h ч $m мин' : '$m мин';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final s = profile.stats;
    final items = [
      ('Сыграно партий', '${s.gamesPlayed}', Icons.sports_esports_rounded),
      ('Средний счёт', '${s.averageScore}', Icons.functions_rounded),
      ('Слияний', '${s.totalMerges}', Icons.merge_rounded),
      ('Объединено блоков', '${s.totalMergedTiles}', Icons.grid_view_rounded),
      ('Максимальное число', s.maxTile == 0 ? '—' : '${s.maxTile}', Icons.trending_up_rounded),
      ('Лучшая цепочка', '×${s.bestChain}', Icons.link_rounded),
      ('Лучшее комбо', '×${s.bestCombo}', Icons.bolt_rounded),
      ('Разбито камней', '${s.stonesDestroyed}', Icons.landscape_rounded),
      ('Бонусов использовано', '${s.bonusesUsed}', Icons.auto_fix_high_rounded),
      ('Целей дня', '${s.dailyCompleted}', Icons.flag_rounded),
      ('Время в игре', _duration(s.playTimeSeconds), Icons.schedule_rounded),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Рекорды', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final m in ModeRegistry.modes)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Panel(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        child: Column(
                          children: [
                            FittedBox(
                              child: Text(m.title, style: TextStyle(color: context.colors.inkSoft, fontWeight: FontWeight.w700)),
                            ),
                            FittedBox(
                              child: Text(
                                '${profile.bestFor(m.id)}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                            ),
                            Text(
                              'партий: ${s.gamesByMode[m.id] ?? 0}',
                              style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Всё время', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            for (final (label, value, icon) in items) ...[
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, color: context.colors.accent),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
