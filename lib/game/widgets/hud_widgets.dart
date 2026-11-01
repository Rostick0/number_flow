import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../shared/theme/app_colors.dart';
import '../mechanics/spawn_rule.dart';
import '../models/tile.dart';
import 'tile_view.dart';

/// Thin bar showing time until the next flow tick. Repaints itself from a
/// ticker by polling [progress], so the game state never rebuilds for it.
class FlowBar extends StatefulWidget {
  const FlowBar({super.key, required this.progress, required this.slow});

  final double Function() progress;
  final bool slow;

  @override
  State<FlowBar> createState() => _FlowBarState();
}

class _FlowBarState extends State<FlowBar> with SingleTickerProviderStateMixin {
  final _value = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _value.value = widget.progress())..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: CustomPaint(
          painter: _FlowBarPainter(_value, widget.slow ? AppColors.ice : AppColors.accent),
        ),
      ),
    );
  }
}

class _FlowBarPainter extends CustomPainter {
  _FlowBarPainter(this.value, this.color) : super(repaint: value);

  final ValueNotifier<double> value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = AppColors.board,
    );
    final w = size.width * value.value.clamp(0.0, 1.0);
    if (w <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, size.height), r),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_FlowBarPainter old) => old.color != color;
}

/// How full the board is; turns red as overflow approaches.
class FillIndicator extends StatelessWidget {
  const FillIndicator({super.key, required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final color = ratio < 0.6
        ? AppColors.success
        : ratio < 0.8
            ? AppColors.coin
            : AppColors.danger;
    return Row(
      children: [
        const Icon(Icons.water_drop_rounded, size: 16, color: AppColors.inkSoft),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: ratio),
              duration: const Duration(milliseconds: 250),
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.board,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(ratio * 100).round()}%',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

class NextTilePreview extends StatelessWidget {
  const NextTilePreview({super.key, required this.next, this.size = 40});

  final SpawnSpec next;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tile = Tile(
      id: 0,
      value: next.value,
      kind: next.isStone ? TileKind.stone : TileKind.number,
      frozenTicks: next.frozen ? 1 : 0,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'ДАЛЕЕ',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkSoft, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
          child: TileFace(
            key: ValueKey('${next.value}-${next.isStone}-${next.frozen}'),
            tile: tile,
            size: size,
          ),
        ),
      ],
    );
  }
}

/// Number that animates towards its new value.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, v, _) => Text('${v.round()}', style: style, maxLines: 1),
    );
  }
}
