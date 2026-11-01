import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio/audio_service.dart';
import '../../services/audio/feedback_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../profile/economy.dart';
import '../profile/profile_controller.dart';

Future<void> showDailyRewardDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _DailyRewardDialog(),
    );

class _DailyRewardDialog extends ConsumerWidget {
  const _DailyRewardDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(profileProvider.notifier);
    final streak = controller.nextLoginStreak;
    final weekDay = (streak - 1) % Economy.loginRewards.length;
    final reward = Economy.loginReward(streak);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ежедневная награда', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                'День $streak подряд',
                style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              LoginStreakStrip(highlight: weekDay),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    controller.claimLogin();
                    ref.read(feedbackProvider).play(Sfx.reward);
                    Navigator.of(context).pop();
                  },
                  icon: const CoinIcon(size: 22),
                  label: Text('Забрать +$reward'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seven-day reward strip; days before [highlight] are shown as collected.
class LoginStreakStrip extends StatelessWidget {
  const LoginStreakStrip({super.key, required this.highlight, this.claimedToday = false});

  final int highlight;
  final bool claimedToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < Economy.loginRewards.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _Day(
                day: i + 1,
                reward: Economy.loginRewards[i],
                done: i < highlight || (claimedToday && i == highlight),
                current: i == highlight,
              ),
            ),
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.reward, required this.done, required this.current});

  final int day;
  final int reward;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final bg = current ? AppColors.accent : (done ? AppColors.success : AppColors.background);
    final fg = current || done ? Colors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('Д$day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 4),
          done && !current
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : const CoinIcon(size: 18),
          const SizedBox(height: 4),
          FittedBox(
            child: Text('$reward', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg)),
          ),
        ],
      ),
    );
  }
}
