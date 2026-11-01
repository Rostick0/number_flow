import 'position.dart';
import 'tile.dart';

/// Mutable square grid of tiles owned by the engine.
///
/// The UI never receives a [Board]; it gets an immutable copy of [cells].
class Board {
  Board(this.size) : _cells = List<Tile?>.filled(size * size, null);

  Board._(this.size, this._cells);

  final int size;
  final List<Tile?> _cells;

  int get cellCount => size * size;

  Tile? operator [](Pos p) => _cells[p.row * size + p.col];

  void operator []=(Pos p, Tile? tile) => _cells[p.row * size + p.col] = tile;

  List<Tile?> get cells => List.unmodifiable(_cells);

  Iterable<Pos> get positions sync* {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        yield Pos(r, c);
      }
    }
  }

  Iterable<Pos> get occupied => positions.where((p) => this[p] != null);

  Iterable<Pos> get empty => positions.where((p) => this[p] == null);

  int get occupiedCount => _cells.where((t) => t != null).length;

  double get fillRatio => occupiedCount / cellCount;

  int get maxValue => _cells.fold(
        0,
        (m, t) => t != null && !t.isStone && t.value > m ? t.value : m,
      );

  Pos? find(int tileId) {
    for (final p in positions) {
      if (this[p]?.id == tileId) return p;
    }
    return null;
  }

  Board copy() => Board._(size, List<Tile?>.of(_cells));

  List<dynamic> toJson() => _cells.map((t) => t?.toJson()).toList();

  static Board fromJson(int size, List<dynamic> json) => Board._(
        size,
        json
            .map((t) => t == null ? null : Tile.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
