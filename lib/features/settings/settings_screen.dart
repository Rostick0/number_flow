import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../gameplay/saved_game.dart';
import '../profile/profile_controller.dart';
import 'rules_dialog.dart';
import 'theme_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить прогресс?'),
        content: const Text('Монеты, бонусы, купленные темы, рекорды, статистика и достижения будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.danger),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(profileProvider.notifier).resetProgress();
    ref.read(savedGameRepositoryProvider).clear();
    if (context.mounted) showToast(context, 'Прогресс сброшен');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(profileProvider.select((p) => p.settings));
    final profile = ref.read(profileProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_rounded),
                    title: const Text('Звук', style: TextStyle(fontWeight: FontWeight.w700)),
                    value: settings.sound,
                    onChanged: (v) => profile.updateSettings((s) => s.copyWith(sound: v)),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.music_note_rounded),
                    title: const Text('Музыка', style: TextStyle(fontWeight: FontWeight.w700)),
                    value: settings.music,
                    onChanged: (v) => profile.updateSettings((s) => s.copyWith(music: v)),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration_rounded),
                    title: const Text('Вибрация', style: TextStyle(fontWeight: FontWeight.w700)),
                    value: settings.vibration,
                    onChanged: (v) => profile.updateSettings((s) => s.copyWith(vibration: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Тема', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 12),
                  ThemePicker(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text('Как играть', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showRulesDialog(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.restart_alt_rounded, color: context.colors.danger),
                    title: Text(
                      'Сбросить прогресс',
                      style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.danger),
                    ),
                    onTap: () => _confirmReset(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Number Flow 1.0.0\nПрогресс хранится только на этом устройстве.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
