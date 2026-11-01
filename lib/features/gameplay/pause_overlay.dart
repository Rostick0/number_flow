import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_colors.dart';
import '../profile/profile_controller.dart';
import '../settings/rules_dialog.dart';
import 'game_controller.dart';

class PauseOverlay extends ConsumerWidget {
  const PauseOverlay({super.key, required this.launch});

  final GameLaunch launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider(launch).notifier);
    final settings = ref.watch(profileProvider.select((p) => p.settings));
    final profile = ref.read(profileProvider.notifier);

    return ModalBarrierOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Пауза',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Партия сохранена — её можно продолжить позже',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: controller.resume,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Продолжить'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: controller.restart,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Начать заново'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showRulesDialog(context),
            icon: const Icon(Icons.help_outline_rounded),
            label: const Text('Как играть'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home_rounded),
            label: const Text('В меню'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Toggle(
                icon: settings.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                label: 'Звук',
                on: settings.sound,
                onTap: () => profile.updateSettings((s) => s.copyWith(sound: !s.sound)),
              ),
              const SizedBox(width: 12),
              _Toggle(
                icon: settings.vibration ? Icons.vibration_rounded : Icons.mobile_off_rounded,
                label: 'Вибрация',
                on: settings.vibration,
                onTap: () => profile.updateSettings((s) => s.copyWith(vibration: !s.vibration)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.label, required this.on, required this.onTap});

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: on,
      label: label,
      child: Material(
        color: on ? AppColors.accent : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 52,
            child: Icon(icon, color: on ? Colors.white : AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}

/// Dimmed full-screen layer with a centered card.
class ModalBarrierOverlay extends StatelessWidget {
  const ModalBarrierOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, t, child) => ColoredBox(
          color: AppColors.ink.withValues(alpha: 0.45 * t),
          child: Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(padding: const EdgeInsets.all(22), child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
