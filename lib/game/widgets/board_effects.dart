import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../models/game_events.dart';
import '../models/tile.dart';
import 'board_geometry.dart';
import 'tile_view.dart';

/// Transient overlay effects driven by engine events: merge ghosts,
/// particle bursts, floating points and level banners. Each effect owns its
/// animation, so the board itself is not rebuilt while effects play.
class BoardEffects extends StatefulWidget {
  const BoardEffects({super.key, required this.events, required this.geometry});

  final Stream<List<GameEvent>> events;
  final BoardGeometry geometry;

  @override
  State<BoardEffects> createState() => _BoardEffectsState();
}

class _BoardEffectsState extends State<BoardEffects> {
  final _effects = <Key, Widget>{};
  late StreamSubscription<List<GameEvent>> _sub;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.events.listen(_onEvents);
  }

  @override
  void didUpdateWidget(BoardEffects old) {
    super.didUpdateWidget(old);
    if (old.events != widget.events) {
      _sub.cancel();
      _sub = widget.events.listen(_onEvents);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _add(Widget Function(Key key, VoidCallback done) build) {
    final key = ValueKey(_counter++);
    _effects[key] = build(key, () {
      if (mounted) setState(() => _effects.remove(key));
    });
  }

  void _onEvents(List<GameEvent> events) {
    if (!mounted) return;
    if (events.isEmpty) {
      setState(_effects.clear);
      return;
    }
    final g = widget.geometry;
    var added = false;
    for (final e in events) {
      switch (e) {
        case MergeHappened():
          for (final (tile, from) in e.consumed) {
            _add((k, done) => _Ghost(
                  key: k,
                  tile: tile,
                  size: g.cell,
                  from: g.topLeft(from),
                  to: g.topLeft(e.anchor),
                  onDone: done,
                ));
          }
          _add((k, done) => _Burst(
                key: k,
                center: g.center(e.anchor),
                color: TilePalette.colorFor(e.resultTile.value),
                radius: g.cell * (0.9 + 0.15 * e.chain),
                count: 12 + 4 * e.chain,
                onDone: done,
              ));
          _add((k, done) => _FloatingText(
                key: k,
                center: g.center(e.anchor),
                text: '+${e.points}',
                caption: e.chain > 1 ? 'Цепь ×${e.chain}' : (e.doubled ? 'Double!' : null),
                fontSize: g.cell * 0.32,
                onDone: done,
              ));
          added = true;
        case StoneDestroyed():
          _add((k, done) => _Burst(
                key: k,
                center: g.center(e.at),
                color: AppColors.stone,
                radius: g.cell * 0.8,
                count: 10,
                onDone: done,
              ));
          added = true;
        case TileRemoved():
          _add((k, done) => _Burst(
                key: k,
                center: g.center(e.at),
                color: e.tile.isStone ? AppColors.stone : TilePalette.colorFor(e.tile.value),
                radius: g.cell * 0.8,
                count: 14,
                onDone: done,
              ));
          added = true;
        case LevelUp():
          _add((k, done) => _Banner(
                key: k,
                text: 'Уровень ${e.level}',
                fontSize: g.cell * 0.42,
                onDone: done,
              ));
          added = true;
        default:
          break;
      }
    }
    if (added) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(clipBehavior: Clip.none, children: _effects.values.toList()),
    );
  }
}

/// Plays a one-shot animation of [duration] and then calls [onDone].
abstract class _OneShot extends StatefulWidget {
  const _OneShot({super.key, required this.onDone});

  final VoidCallback onDone;
  Duration get duration;
  Widget buildFrame(BuildContext context, double t);

  @override
  State<_OneShot> createState() => _OneShotState();
}

class _OneShotState extends State<_OneShot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Stack(
              clipBehavior: Clip.none,
              children: [widget.buildFrame(context, _c.value)],
            ),
          ),
        ),
      );
}

class _Ghost extends _OneShot {
  const _Ghost({
    super.key,
    required this.tile,
    required this.size,
    required this.from,
    required this.to,
    required super.onDone,
  });

  final Tile tile;
  final double size;
  final Offset from;
  final Offset to;

  @override
  Duration get duration => const Duration(milliseconds: 200);

  @override
  Widget buildFrame(BuildContext context, double t) {
    final eased = Curves.easeIn.transform(t);
    final pos = Offset.lerp(from, to, eased)!;
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Opacity(
        opacity: 1 - eased * 0.7,
        child: Transform.scale(
          scale: 1 - eased * 0.35,
          child: TileFace(tile: tile, size: size),
        ),
      ),
    );
  }
}

class _Burst extends _OneShot {
  const _Burst({
    super.key,
    required this.center,
    required this.color,
    required this.radius,
    required this.count,
    required super.onDone,
  });

  final Offset center;
  final Color color;
  final double radius;
  final int count;

  @override
  Duration get duration => const Duration(milliseconds: 650);

  @override
  Widget buildFrame(BuildContext context, double t) => Positioned.fill(
        child: CustomPaint(
          painter: _BurstPainter(center, color, radius, count, t, center.hashCode),
        ),
      );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.center, this.color, this.radius, this.count, this.t, this.seed);

  final Offset center;
  final Color color;
  final double radius;
  final int count;
  final double t;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final eased = Curves.easeOutCubic.transform(t);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + rnd.nextDouble() * 0.5;
      final dist = radius * (0.45 + rnd.nextDouble() * 0.6) * eased;
      final r = radius * (0.06 + rnd.nextDouble() * 0.05) * (1 - t);
      final p = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      paint.color = (i.isEven ? color : Colors.white).withValues(alpha: (1 - t) * 0.95);
      canvas.drawCircle(p, r, paint);
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06 * (1 - t)
      ..color = color.withValues(alpha: (1 - t) * 0.6);
    canvas.drawCircle(center, radius * 0.7 * eased, ring);
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

class _FloatingText extends _OneShot {
  const _FloatingText({
    super.key,
    required this.center,
    required this.text,
    required this.caption,
    required this.fontSize,
    required super.onDone,
  });

  final Offset center;
  final String text;
  final String? caption;
  final double fontSize;

  @override
  Duration get duration => const Duration(milliseconds: 900);

  @override
  Widget buildFrame(BuildContext context, double t) {
    final rise = Curves.easeOut.transform(t) * fontSize * 2.2;
    final opacity = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
    const width = 160.0;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - fontSize - rise,
      width: width,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OutlinedText(text, fontSize: fontSize, color: AppColors.ink),
            if (caption != null)
              _OutlinedText(caption!, fontSize: fontSize * 0.7, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _Banner extends _OneShot {
  const _Banner({super.key, required this.text, required this.fontSize, required super.onDone});

  final String text;
  final double fontSize;

  @override
  Duration get duration => const Duration(milliseconds: 1300);

  @override
  Widget buildFrame(BuildContext context, double t) {
    final appear = Curves.easeOutBack.transform((t / 0.25).clamp(0.0, 1.0));
    final opacity = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
    return Positioned.fill(
      child: Center(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.6 + 0.4 * appear,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: fontSize, vertical: fontSize * 0.45),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(fontSize),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16)],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedText extends StatelessWidget {
  const _OutlinedText(this.text, {required this.fontSize, required this.color});

  final String text;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, height: 1.1);
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.18
              ..color = Colors.white,
          ),
        ),
        Text(text, style: style.copyWith(color: color)),
      ],
    );
  }
}
