import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/models/bonus_type.dart';
import '../../game/widgets/board_view.dart';
import '../../game/widgets/bonus_bar.dart';
import '../../game/widgets/hud_widgets.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../shop/bonus_refill_sheet.dart';
import 'game_controller.dart';
import 'game_view_state.dart';
import 'game_over_overlay.dart';
import 'pause_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.launch});

  final GameLaunch launch;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  GameController get _controller => ref.read(gameControllerProvider(widget.launch).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _controller.pause();
      _controller.saveNow();
    }
  }

  Future<void> _onBonus(BonusType type) async {
    final result = _controller.requestBonus(type);
    if (result != BonusRequest.needsStock) return;
    _controller.pause();
    final restocked = await showBonusRefillSheet(context, type);
    if (!mounted) return;
    _controller.resume();
    if (restocked) _controller.requestBonus(type);
  }

  @override
  Widget build(BuildContext context) {
    final provider = gameControllerProvider(widget.launch);
    final paused = ref.watch(provider.select((s) => s.paused));
    final hasSummary = ref.watch(provider.select((s) => s.summary != null));
    final removeMode = ref.watch(provider.select((s) => s.removeMode));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (hasSummary) {
          Navigator.of(context).pop();
        } else if (paused) {
          _controller.resume();
        } else {
          _controller.pause();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      _Header(launch: widget.launch),
                      const SizedBox(height: 10),
                      _InfoRow(launch: widget.launch),
                      const SizedBox(height: 10),
                      Expanded(
                        // The flow bar sits right on top of the board and
                        // matches its width on any screen shape.
                        child: LayoutBuilder(builder: (context, c) {
                          const barGap = 14.0;
                          final extent = math.min(c.maxWidth, c.maxHeight - barGap);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: extent, child: _FlowBarSlot(launch: widget.launch)),
                              const SizedBox(height: barGap - 6),
                              SizedBox.square(
                                dimension: extent,
                                child: _Board(launch: widget.launch),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 22,
                        child: removeMode
                            ? Text(
                                'Нажми на блок, чтобы убрать его',
                                style: TextStyle(color: context.colors.danger, fontWeight: FontWeight.w800),
                              )
                            : _Fill(launch: widget.launch),
                      ),
                      const SizedBox(height: 10),
                      _Bonuses(launch: widget.launch, onPressed: _onBonus),
                    ],
                  ),
                ),
              ),
            ),
            if (paused && !hasSummary) PauseOverlay(launch: widget.launch),
            if (hasSummary) GameOverOverlay(launch: widget.launch),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.launch});

  final GameLaunch launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = gameControllerProvider(launch);
    final score = ref.watch(provider.select((s) => s.score));
    final best = ref.watch(provider.select((s) => s.best));
    return Row(
      children: [
        _SquareButton(
          icon: Icons.pause_rounded,
          tooltip: 'Пауза',
          onTap: () => ref.read(provider.notifier).pause(),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _ScoreBox(
            label: 'СЧЁТ',
            child: AnimatedCount(
              value: score,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _ScoreBox(
            label: 'РЕКОРД',
            child: Text(
              '$best',
              maxLines: 1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.1,
                color: context.colors.inkSoft,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: context.colors.inkSoft,
            ),
          ),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox.square(dimension: 52, child: Icon(icon, size: 28)),
        ),
      ),
    );
  }
}

class _InfoRow extends ConsumerWidget {
  const _InfoRow({required this.launch});

  final GameLaunch launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = gameControllerProvider(launch);
    final level = ref.watch(provider.select((s) => s.level));
    final time = ref.watch(provider.select((s) => s.timeSecondsLeft));
    final target = ref.watch(provider.select((s) => s.targetScore));
    final combo = ref.watch(provider.select((s) => s.combo));
    final multiplier = ref.watch(provider.select((s) => s.comboMultiplier));
    final doubleArmed = ref.watch(provider.select((s) => s.doubleArmed));
    final slow = ref.watch(provider.select((s) => s.slowSecondsLeft));
    final next = ref.watch(provider.select((s) => s.next));

    return SizedBox(
      height: 62,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Chip(icon: Icons.layers_rounded, text: 'Ур. $level'),
                if (time != null)
                  _Chip(
                    icon: Icons.timer_outlined,
                    text: '${time ~/ 60}:${(time % 60).toString().padLeft(2, '0')}',
                    color: time <= 15 ? context.colors.danger : null,
                  ),
                if (target != null) _Chip(icon: Icons.flag_rounded, text: 'Цель $target'),
                if (combo >= 2)
                  _Chip(
                    icon: Icons.bolt_rounded,
                    text: 'Комбо ×${multiplier.toStringAsFixed(1)}',
                    color: context.colors.accent,
                  ),
                if (doubleArmed) _Chip(icon: Icons.filter_2_rounded, text: 'Double', color: context.colors.accent),
                if (slow > 0)
                  _Chip(icon: Icons.hourglass_bottom_rounded, text: '${slow + 1} c', color: context.colors.accent),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NextTilePreview(next: next),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color == null ? context.colors.ink : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowBarSlot extends ConsumerWidget {
  const _FlowBarSlot({required this.launch});

  final GameLaunch launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = gameControllerProvider(launch);
    final slow = ref.watch(provider.select((s) => s.slowSecondsLeft > 0));
    final controller = ref.read(provider.notifier);
    return FlowBar(progress: () => controller.tickProgress, slow: slow);
  }
}

class _Board extends ConsumerWidget {
  const _Board({required this.launch});

  final GameLaunch launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = gameControllerProvider(launch);
    final slice = ref.watch(provider.select((s) => BoardSlice(
          cells: s.cells,
          size: s.size,
          selected: s.selected,
          removeMode: s.removeMode,
          inDanger: s.inDanger,
          generation: s.generation,
        )));
    final controller = ref.read(provider.notifier);
    return BoardView(
      slice: slice,
      events: controller.events,
      onTap: controller.tapCell,
      onSwipe: controller.swipe,
    );
  }
}

class _Fill extends ConsumerWidget {
  const _Fill({required this.launch});

  final GameLaunch launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = ref.watch(gameControllerProvider(launch).select((s) => s.fillRatio));
    return FillIndicator(ratio: ratio);
  }
}

/// Value-equal wrapper so the bonus bar rebuilds only when a slot changes.
class _Slots {
  const _Slots(this.slots);

  final Map<BonusType, BonusSlot> slots;

  @override
  bool operator ==(Object other) => other is _Slots && mapEquals(other.slots, slots);

  @override
  int get hashCode => Object.hashAll(slots.values);
}

class _Bonuses extends ConsumerWidget {
  const _Bonuses({required this.launch, required this.onPressed});

  final GameLaunch launch;
  final void Function(BonusType) onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = gameControllerProvider(launch);
    final slots = ref.watch(provider.select((s) => _Slots(s.bonuses))).slots;
    final removeMode = ref.watch(provider.select((s) => s.removeMode));
    final doubleArmed = ref.watch(provider.select((s) => s.doubleArmed));
    final slow = ref.watch(provider.select((s) => s.slowSecondsLeft > 0));
    return BonusBar(
      onPressed: onPressed,
      buttons: [
        for (final t in BonusType.values)
          BonusButtonData(
            type: t,
            stock: slots[t]!.stock,
            usesLeft: slots[t]!.usesLeft,
            usable: slots[t]!.usable,
            active: switch (t) {
              BonusType.remove => removeMode,
              BonusType.doubleMerge => doubleArmed,
              BonusType.slowMotion => slow,
              _ => false,
            },
          ),
      ],
    );
  }
}
