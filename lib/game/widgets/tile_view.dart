import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../models/tile.dart';

/// Visual of a single block. Pops in on creation and bounces on value change.
class TileView extends StatefulWidget {
  const TileView({
    super.key,
    required this.tile,
    required this.size,
    this.selected = false,
    this.removeTarget = false,
  });

  final Tile tile;
  final double size;
  final bool selected;
  final bool removeTarget;

  @override
  State<TileView> createState() => _TileViewState();
}

class _TileViewState extends State<TileView> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late Animation<double> _scale = _spawnCurve();

  Animation<double> _spawnCurve() => TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.08), weight: 70),
        TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));

  // Curves live inside the items: TweenSequence needs t within 0..1, so an
  // overshooting curve cannot wrap the whole sequence.
  Animation<double> _mergeCurve() => TweenSequence([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.22).chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.22, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60,
        ),
      ]).animate(_pop);

  @override
  void initState() {
    super.initState();
    _pop.forward();
  }

  @override
  void didUpdateWidget(TileView old) {
    super.didUpdateWidget(old);
    if (old.tile.value != widget.tile.value) {
      _scale = _mergeCurve();
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AnimatedScale(
        scale: widget.selected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: TileFace(
          tile: widget.tile,
          size: widget.size,
          selected: widget.selected,
          removeTarget: widget.removeTarget,
        ),
      ),
    );
  }
}

/// Stateless tile drawing, reused by previews and merge ghosts.
class TileFace extends StatelessWidget {
  const TileFace({
    super.key,
    required this.tile,
    required this.size,
    this.selected = false,
    this.removeTarget = false,
  });

  final Tile tile;
  final double size;
  final bool selected;
  final bool removeTarget;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    final base = tile.isStone ? context.colors.stone : context.colors.tileColor(tile.value);
    final edge = tile.isStone ? context.colors.stoneDark : AppColors.edgeFor(base);
    final border = removeTarget
        ? Border.all(color: context.colors.danger, width: size * 0.06)
        : selected
            ? Border.all(color: Colors.white, width: size * 0.07)
            : null;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: edge,
          borderRadius: radius,
          boxShadow: selected
              ? [BoxShadow(color: base.withValues(alpha: 0.55), blurRadius: size * 0.25)]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: size * 0.06),
          child: DecoratedBox(
            decoration: BoxDecoration(color: base, borderRadius: radius, border: border),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (tile.isStone) _StoneMarks(size: size) else _Label(tile: tile, size: size),
                if (tile.isFrozen) _Ice(size: size, ticks: tile.frozenTicks, radius: radius),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.tile, required this.size});

  final Tile tile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = '${tile.value}';
    final scale = switch (text.length) { 1 => 0.46, 2 => 0.42, 3 => 0.34, 4 => 0.27, _ => 0.22 };
    return Center(
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: context.colors.tileText(tile.value),
          fontSize: size * scale,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _StoneMarks extends StatelessWidget {
  const _StoneMarks({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _StonePainter(context.colors.stoneDark));
}

class _StonePainter extends CustomPainter {
  _StonePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.55);
    final s = size.width;
    canvas.drawCircle(Offset(s * 0.32, s * 0.36), s * 0.09, paint);
    canvas.drawCircle(Offset(s * 0.64, s * 0.3), s * 0.06, paint);
    canvas.drawCircle(Offset(s * 0.58, s * 0.64), s * 0.11, paint);
    canvas.drawCircle(Offset(s * 0.3, s * 0.68), s * 0.05, paint);
  }

  @override
  bool shouldRepaint(_StonePainter old) => old.color != color;
}

class _Ice extends StatelessWidget {
  const _Ice({required this.size, required this.ticks, required this.radius});

  final double size;
  final int ticks;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.ice.withValues(alpha: 0.45),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: size * 0.045),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: Icon(Icons.ac_unit_rounded, size: size * 0.22, color: Colors.white),
        ),
      ),
    );
  }
}
