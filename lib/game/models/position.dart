/// A cell coordinate on the board. Row 0 is the top (flow entry) row.
class Pos {
  const Pos(this.row, this.col);

  final int row;
  final int col;

  Pos operator +(Direction d) => Pos(row + d.dRow, col + d.dCol);

  bool isInside(int size) => row >= 0 && row < size && col >= 0 && col < size;

  bool isAdjacentTo(Pos other) =>
      (row - other.row).abs() + (col - other.col).abs() == 1;

  Iterable<Pos> neighbours(int size) sync* {
    for (final d in Direction.values) {
      final p = this + d;
      if (p.isInside(size)) yield p;
    }
  }

  List<int> toJson() => [row, col];

  static Pos fromJson(List<dynamic> json) =>
      Pos(json[0] as int, json[1] as int);

  @override
  bool operator ==(Object other) =>
      other is Pos && other.row == row && other.col == col;

  @override
  int get hashCode => row * 31 + col;

  @override
  String toString() => 'Pos($row, $col)';
}

enum Direction {
  up(-1, 0),
  down(1, 0),
  left(0, -1),
  right(0, 1);

  const Direction(this.dRow, this.dCol);

  final int dRow;
  final int dCol;
}
