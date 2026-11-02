import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/models/game_events.dart';
import '../../game/models/tile.dart';
import '../../game/widgets/hud_widgets.dart';
import '../../game/widgets/tile_view.dart';
import '../../services/ads/ad_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../profile/game_result.dart';
import '../profile/profile_controller.dart';
import 'game_controller.dart';
import 'pause_overlay.dart';

class GameOverOverlay extends ConsumerStatefulWidget {
  const GameOverOverlay({super.key, required this.launch});

  final GameLaunch launch;

  @override
  ConsumerState<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends ConsumerState<GameOverOverlay> {
  bool _busy = false;

  GameController get _controller => ref.read(gameControllerProvider(widget.launch).notifier);

  /// Interstitials only ever appear here: after a session, before the next.
  Future<void> _betweenSessions(VoidCallback then) async {
    if (_busy) return;
    setState(() => _busy = true);
    final adsRemoved = ref.read(profileProvider).adsRemoved;
    await ref.read(adServiceProvider).maybeShowInterstitial(adsRemoved: adsRemoved);
    if (!mounted) return;
    setState(() => _busy = false);
    then();
  }

  Future<void> _double() async {
    setState(() => _busy = true);
    final ok = await _controller.doubleReward();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) showToast(context, 'Награда не получена');
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(gameControllerProvider(widget.launch).select((s) => s.summary));
    final reason = ref.watch(gameControllerProvider(widget.launch).select((s) => s.overReason));
    if (summary == null) return const SizedBox.shrink();
    final r = summary.result;
    final timeUp = reason == GameOverReason.timeUp;

    return ModalBarrierOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            timeUp ? 'Время вышло' : 'Поле переполнено',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.colors.inkSoft),
          ),
          const SizedBox(height: 6),
          Center(
            child: AnimatedCount(
              value: r.score,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, height: 1.1),
            ),
          ),
          if (summary.newRecord) const _RecordBadge(),
          if (!summary.newRecord)
            Text(
              'Рекорд: ${summary.previousBest}',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.inkSoft, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 16),
          _StatsRow(summary: summary),
          const SizedBox(height: 14),
          _Rewards(summary: summary),
          const SizedBox(height: 16),
          if (summary.coins > 0)
            ValueListenableBuilder<bool>(
              valueListenable: ref.read(adServiceProvider).rewardedReady,
              builder: (context, ready, _) => FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: context.colors.coin),
                onPressed: ready && !summary.doubled && !_busy ? _double : null,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: Text(
                  summary.doubled
                      ? 'Награда удвоена'
                      : ready
                          ? 'Удвоить награду за рекламу'
                          : 'Удвоение недоступно',
                ),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : () => _betweenSessions(_controller.restart),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Ещё раз'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _betweenSessions(() => Navigator.of(context).pop()),
            icon: const Icon(Icons.home_rounded),
            label: const Text('В меню'),
          ),
        ],
      ),
    );
  }
}

class _RecordBadge extends StatelessWidget {
  const _RecordBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: context.colors.coin, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('Новый рекорд!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

  final RewardSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary.result.stats;
    return Row(
      children: [
        Expanded(child: _Stat(label: 'Слияний', value: '${s.merges}')),
        Expanded(
          child: Column(
            children: [
              if (s.maxValue > 0)
                TileFace(tile: Tile(id: 0, value: s.maxValue), size: 34)
              else
                const SizedBox(height: 34),
              const SizedBox(height: 4),
              Text('Макс. число', style: TextStyle(fontSize: 12, color: context.colors.inkSoft)),
            ],
          ),
        ),
        Expanded(child: _Stat(label: 'Лучшая цепь', value: '×${s.maxChain}')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 34,
          child: Center(
            child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: context.colors.inkSoft)),
      ],
    );
  }
}

class _Rewards extends StatelessWidget {
  const _Rewards({required this.summary});

  final RewardSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.doubled ? summary.coins * 2 : summary.coins;
    final notes = [
      if (summary.dailyGoalReached) 'Цель дня выполнена!',
      for (final q in summary.completedQuests) 'Задание: $q',
      for (final a in summary.unlockedAchievements) 'Достижение: $a',
    ];
    return Panel(
      color: context.colors.background,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CoinIcon(size: 24),
              const SizedBox(width: 8),
              AnimatedCount(
                value: total,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const Text(' монет', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: context.colors.success),
                  const SizedBox(width: 6),
                  Expanded(child: Text(n, style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          if (summary.completedQuests.isNotEmpty || summary.unlockedAchievements.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Забери награды в разделе «Задания»',
                style: TextStyle(fontSize: 12, color: context.colors.inkSoft),
              ),
            ),
        ],
      ),
    );
  }
}
