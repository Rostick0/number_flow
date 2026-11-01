import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio/audio_service.dart';
import '../../services/audio/feedback_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../profile/economy.dart';
import '../profile/profile_controller.dart';
import 'achievement.dart';
import 'daily_reward_dialog.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Задания'),
          actions: const [Padding(padding: EdgeInsets.only(right: 12), child: CoinBadge())],
          bottom: const TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [Tab(text: 'Ежедневные'), Tab(text: 'Достижения')],
          ),
        ),
        body: const ContentWidth(
          child: TabBarView(children: [_DailyTab(), _AchievementsTab()]),
        ),
      ),
    );
  }
}

class _DailyTab extends ConsumerWidget {
  const _DailyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);
    final canClaim = controller.canClaimLogin;
    final streak = canClaim ? controller.nextLoginStreak : profile.loginStreak;
    final quests = profile.quests?.quests ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Награда за вход · день $streak',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 12),
              LoginStreakStrip(
                highlight: (streak - 1) % Economy.loginRewards.length,
                claimedToday: !canClaim,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: canClaim ? () => showDailyRewardDialog(context) : null,
                child: Text(canClaim ? 'Забрать награду' : 'Возвращайся завтра'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Задания на сегодня', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        for (final q in quests) ...[
          _ProgressCard(
            title: q.template.title,
            progress: q.progress,
            target: q.template.target,
            reward: q.template.reward,
            claimed: q.claimed,
            onClaim: () {
              controller.claimQuest(q.id);
              ref.read(feedbackProvider).play(Sfx.reward);
            },
          ),
          const SizedBox(height: 10),
        ],
        const Text(
          'Новые задания появляются каждый день.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _AchievementsTab extends ConsumerWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);
    final sorted = [...achievements]..sort((a, b) {
        int rank(Achievement x) {
          if (x.isUnlocked(profile) && !profile.claimedAchievements.contains(x.id)) return 0;
          if (!x.isUnlocked(profile)) return 1;
          return 2;
        }

        return rank(a).compareTo(rank(b));
      });
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = sorted[i];
        return _ProgressCard(
          title: a.title,
          subtitle: a.description,
          progress: a.progress(profile),
          target: a.target,
          reward: a.reward,
          claimed: profile.claimedAchievements.contains(a.id),
          onClaim: () {
            controller.claimAchievement(a.id);
            ref.read(feedbackProvider).play(Sfx.reward);
          },
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.progress,
    required this.target,
    required this.reward,
    required this.claimed,
    required this.onClaim,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final int progress;
  final int target;
  final int reward;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final done = progress >= target;
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: target == 0 ? 1 : progress / target,
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation(done ? AppColors.success : AppColors.accent),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$progress / $target', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (claimed)
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32)
          else
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(76, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: done ? onClaim : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CoinIcon(size: 16),
                  const SizedBox(width: 4),
                  Text('$reward'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
