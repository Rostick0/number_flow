import '../models/board.dart';
import '../models/position.dart';

/// Moves tiles once per tick. Swappable so new modes can change the flow.
abstract class FlowRule {
  const FlowRule();

  /// Applies one flow step and returns the cells that received a tile.
  List<Pos> step(Board board);

  /// Cells where new tiles enter the board.
  List<Pos> entryCells(Board board);
}

/// Tiles fall one cell per tick towards the bottom row.
///
/// Rows are scanned bottom-up, so a whole column above a gap shifts down
/// by exactly one cell in a single tick.
class GravityFlowRule extends FlowRule {
  const GravityFlowRule();

  @override
  List<Pos> step(Board board) {
    final moved = <Pos>[];
    for (var r = board.size - 2; r >= 0; r--) {
      for (var c = 0; c < board.size; c++) {
        final from = Pos(r, c);
        final to = Pos(r + 1, c);
        final tile = board[from];
        if (tile != null && board[to] == null) {
          board[to] = tile;
          board[from] = null;
          moved.add(to);
        }
      }
    }
    return moved;
  }

  @override
  List<Pos> entryCells(Board board) =>
      [for (var c = 0; c < board.size; c++) Pos(0, c)];
}
