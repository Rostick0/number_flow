import '../models/board.dart';
import '../models/position.dart';

/// Finds mergeable groups and decides where the merged tile stays.
class MergeRule {
  const MergeRule({this.minGroupSize = 3});

  final int minGroupSize;

  /// All connected groups of equal numbers with at least [minGroupSize] cells,
  /// ordered top-to-bottom by their first cell for determinism.
  List<List<Pos>> findGroups(Board board) {
    final visited = <Pos>{};
    final groups = <List<Pos>>[];
    for (final start in board.positions) {
      if (visited.contains(start)) continue;
      final tile = board[start];
      if (tile == null || !tile.canMerge) continue;
      final group = <Pos>[];
      final queue = <Pos>[start];
      visited.add(start);
      while (queue.isNotEmpty) {
        final p = queue.removeLast();
        group.add(p);
        for (final n in p.neighbours(board.size)) {
          final other = board[n];
          if (visited.contains(n) || other == null) continue;
          if (other.canMerge && other.value == tile.value) {
            visited.add(n);
            queue.add(n);
          }
        }
      }
      if (group.length >= minGroupSize) groups.add(group);
    }
    return groups;
  }

  /// Recently changed cells win; ties go to the lowest, then leftmost cell.
  Pos pickAnchor(List<Pos> group, Set<Pos> recent) {
    final candidates = group.where(recent.contains).toList();
    final pool = candidates.isEmpty ? group : candidates;
    return pool.reduce((a, b) {
      if (a.row != b.row) return a.row > b.row ? a : b;
      return a.col <= b.col ? a : b;
    });
  }

  int resultValue(int value, {required bool doubled}) =>
      doubled ? value * 4 : value * 2;
}
