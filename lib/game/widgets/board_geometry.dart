import 'dart:ui';

import '../models/position.dart';

/// Maps cells to pixels for a square board of [extent] pixels.
class BoardGeometry {
  BoardGeometry(this.extent, this.size)
      : padding = extent * 0.025,
        gap = extent * 0.022 {
    cell = (extent - 2 * padding - (size - 1) * gap) / size;
  }

  final double extent;
  final int size;
  final double padding;
  final double gap;
  late final double cell;

  Offset topLeft(Pos p) =>
      Offset(padding + p.col * (cell + gap), padding + p.row * (cell + gap));

  Offset center(Pos p) => topLeft(p) + Offset(cell / 2, cell / 2);

  Pos? cellAt(Offset local) {
    final col = ((local.dx - padding) / (cell + gap)).floor();
    final row = ((local.dy - padding) / (cell + gap)).floor();
    final p = Pos(row, col);
    return p.isInside(size) ? p : null;
  }
}
