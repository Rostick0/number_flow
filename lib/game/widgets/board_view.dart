import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../models/game_events.dart';
import '../models/position.dart';
import '../models/tile.dart';
import 'board_effects.dart';
import 'board_geometry.dart';
import 'tile_view.dart';

/// What the board needs to render; compared by value to skip rebuilds.
@immutable
class BoardSlice {
  const BoardSlice({
    required this.cells,
    required this.size,
    required this.selected,
    required this.removeMode,
    required this.inDanger,
    required this.generation,
  });

  final List<Tile?> cells;
  final int size;
  final Pos? selected;
  final bool removeMode;
  final bool inDanger;
  final int generation;

  @override
  bool operator ==(Object other) =>
      other is BoardSlice &&
      listEquals(other.cells, cells) &&
      other.size == size &&
      other.selected == selected &&
      other.removeMode == removeMode &&
      other.inDanger == inDanger &&
      other.generation == generation;

  @override
  int get hashCode => Object.hash(Object.hashAll(cells), selected, removeMode, inDanger, generation);
}

/// Square game board: cell grid, animated tiles, effects and gestures.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.slice,
    required this.events,
    required this.onTap,
    required this.onSwipe,
  });

  final BoardSlice slice;
  final Stream<List<GameEvent>> events;
  final void Function(Pos cell) onTap;
  final void Function(Pos cell, Direction direction) onSwipe;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  Offset? _panStart;
  Pos? _panCell;
  bool _panHandled = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final extent = constraints.biggest.shortestSide;
      final g = BoardGeometry(extent, widget.slice.size);
      final s = widget.slice;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final cell = g.cellAt(d.localPosition);
          if (cell != null) widget.onTap(cell);
        },
        onPanStart: (d) {
          _panStart = d.localPosition;
          _panCell = g.cellAt(d.localPosition);
          _panHandled = false;
        },
        onPanUpdate: (d) => _onPanUpdate(d, g),
        onPanEnd: (_) => _panStart = null,
        child: SizedBox.square(
          dimension: extent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _GridPainter(g, context.colors)),
                ),
              ),
              if (s.inDanger)
                Positioned(
                  left: g.padding * 0.5,
                  top: g.padding * 0.5,
                  width: extent - g.padding,
                  height: g.cell + g.padding,
                  child: const _DangerPulse(),
                ),
              for (var i = 0; i < s.cells.length; i++)
                if (s.cells[i] case final tile?)
                  _positionedTile(tile, Pos(i ~/ s.size, i % s.size), g, s),
              Positioned.fill(child: BoardEffects(events: widget.events, geometry: g)),
            ],
          ),
        ),
      );
    });
  }

  Widget _positionedTile(Tile tile, Pos p, BoardGeometry g, BoardSlice s) {
    final offset = g.topLeft(p);
    return AnimatedPositioned(
      key: ValueKey('${s.generation}-${tile.id}'),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      left: offset.dx,
      top: offset.dy,
      width: g.cell,
      height: g.cell,
      child: TileView(
        tile: tile,
        size: g.cell,
        selected: s.selected == p,
        removeTarget: s.removeMode,
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails d, BoardGeometry g) {
    final start = _panStart;
    final cell = _panCell;
    if (start == null || cell == null || _panHandled) return;
    final delta = d.localPosition - start;
    if (delta.distance < g.cell * 0.28) return;
    _panHandled = true;
    final direction = delta.dx.abs() > delta.dy.abs()
        ? (delta.dx > 0 ? Direction.right : Direction.left)
        : (delta.dy > 0 ? Direction.down : Direction.up);
    widget.onSwipe(cell, direction);
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.g, this.colors);

  final BoardGeometry g;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final boardPaint = Paint()..color = colors.board;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(g.extent * 0.05)),
      boardPaint,
    );
    final cellPaint = Paint()..color = colors.cell;
    final entryPaint = Paint()..color = Color.lerp(colors.cell, colors.accent, 0.08)!;
    final radius = Radius.circular(g.cell * 0.22);
    for (var r = 0; r < g.size; r++) {
      for (var c = 0; c < g.size; c++) {
        final rect = g.topLeft(Pos(r, c)) & Size(g.cell, g.cell);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), r == 0 ? entryPaint : cellPaint);
      }
    }
    // Flow direction hint: small chevrons under the entry row.
    final arrow = Paint()
      ..color = colors.accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = g.gap * 0.35;
    for (var c = 0; c < g.size; c++) {
      final x = g.center(Pos(0, c)).dx;
      final y = g.padding + g.cell + g.gap / 2;
      final w = g.gap * 0.7;
      canvas.drawLine(Offset(x - w, y - w * 0.3), Offset(x, y + w * 0.3), arrow);
      canvas.drawLine(Offset(x + w, y - w * 0.3), Offset(x, y + w * 0.3), arrow);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.g.extent != g.extent || old.g.size != g.size || old.colors != colors;
}

class _DangerPulse extends StatefulWidget {
  const _DangerPulse();

  @override
  State<_DangerPulse> createState() => _DangerPulseState();
}

class _DangerPulseState extends State<_DangerPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 0.7).animate(_c),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.danger.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
