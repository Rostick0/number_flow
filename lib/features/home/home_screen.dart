import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../game/models/tile.dart';
import '../../game/modes/game_mode.dart';
import '../../game/modes/mode_registry.dart';
import '../../game/widgets/tile_view.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/fade_route.dart';
import '../achievements/achievements_screen.dart';
import '../achievements/daily_reward_dialog.dart';
import '../gameplay/game_controller.dart';
import '../gameplay/game_screen.dart';
import '../gameplay/saved_game.dart';
import '../profile/profile_controller.dart';
import '../settings/rules_dialog.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../statistics/statistics_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _modeId = ModeRegistry.modes.first.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onboarding());
  }

  Future<void> _onboarding() async {
    final profile = ref.read(profileProvider.notifier);
    if (!ref.read(profileProvider).settings.tutorialSeen) {
      await showRulesDialog(context);
      profile.updateSettings((s) => s.copyWith(tutorialSeen: true));
    }
    if (!mounted) return;
    if (profile.canClaimLogin) await showDailyRewardDialog(context);
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(fadeRoute<void>(page));
    if (!mounted) return;
    ref.invalidate(savedGameProvider);
    ref.read(profileProvider.notifier).refreshDay();
  }

  void _play({required bool resume}) =>
      _open(GameScreen(launch: GameLaunch(_modeId, resume: resume)));

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedGameProvider);
    final canResume = saved != null && saved.modeId == _modeId;

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Настройки',
                            onPressed: () => _open(const SettingsScreen()),
                            icon: const Icon(Icons.settings_rounded),
                          ),
                          const Spacer(),
                          CoinBadge(onTap: () => _open(const ShopScreen())),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 12),
                      const _Logo(),
                      const SizedBox(height: 24),
                      _BestCard(modeId: _modeId),
                      const SizedBox(height: 16),
                      _ModePicker(
                        selected: _modeId,
                        onSelected: (id) => setState(() => _modeId = id),
                      ),
                      const SizedBox(height: 16),
                      if (canResume) ...[
                        FilledButton.icon(
                          onPressed: () => _play(resume: true),
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text('Продолжить · ${saved.score}'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => _play(resume: false),
                          child: const Text('Новая игра'),
                        ),
                      ] else
                        FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 60)),
                          onPressed: () => _play(resume: false),
                          icon: const Icon(Icons.play_arrow_rounded, size: 30),
                          label: const Text('Играть', style: TextStyle(fontSize: 20)),
                        ),
                      const Spacer(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.storefront_rounded,
                              label: 'Магазин',
                              onTap: () => _open(const ShopScreen()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.task_alt_rounded,
                              label: 'Задания',
                              badge: ref.watch(profileProvider.select(claimableRewards)),
                              onTap: () => _open(const AchievementsScreen()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.insights_rounded,
                              label: 'Статистика',
                              onTap: () => _open(const StatisticsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatefulWidget {
  const _Logo();

  @override
  State<_Logo> createState() => _LogoState();
}

class _LogoState extends State<_Logo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const values = [2, 4, 8, 16, 32];
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < values.length; i++)
                  Transform.translate(
                    // A wave flowing through the row of tiles.
                    offset: Offset(0, 8 * _wave(_c.value - i * 0.12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: TileFace(tile: Tile(id: 0, value: values[i]), size: 44),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Number Flow',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const Text(
          'собирай числа, пока поток не захлестнул поле',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Short hop during the first 30% of the cycle, then rest.
  static double _wave(double t) {
    final x = t % 1.0;
    return x < 0.3 ? -math.sin(x / 0.3 * math.pi) : 0;
  }
}

class _BestCard extends ConsumerWidget {
  const _BestCard({required this.modeId});

  final String modeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = ref.watch(profileProvider.select((p) => p.bestFor(modeId)));
    final mode = ModeRegistry.byId(modeId);
    final daily = ref.watch(profileProvider.select((p) => (p.dailyChallengeBest, p.dailyGoalRewarded)));
    final target = mode.targetScore(ref.read(clockProvider)());
    return Panel(
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.coin, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target == null ? 'Лучший результат' : 'Сегодня: цель $target',
                  style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w700),
                ),
                Text(
                  target == null ? '$best' : '${daily.$1}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.15),
                ),
              ],
            ),
          ),
          if (target != null && daily.$2)
            const Tooltip(
              message: 'Цель дня выполнена',
              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 30),
            ),
        ],
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static IconData _icon(GameMode m) => switch (m.id) {
        'time_attack' => Icons.timer_rounded,
        'daily' => Icons.calendar_today_rounded,
        _ => Icons.all_inclusive_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final current = ModeRegistry.byId(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final m in ModeRegistry.modes)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ModeCard(
                    icon: _icon(m),
                    title: m.title,
                    selected: m.id == selected,
                    onTap: () => onSelected(m.id),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            current.subtitle,
            key: ValueKey(current.id),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Column(
                children: [
                  Icon(icon, color: selected ? Colors.white : AppColors.ink),
                  const SizedBox(height: 6),
                  FittedBox(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.badge = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                child: Icon(icon, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
