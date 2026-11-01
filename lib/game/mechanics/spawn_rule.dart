import 'dart:math' as math;

import '../models/board.dart';
import '../models/position.dart';
import '../models/tile.dart';
import 'difficulty.dart';
import 'merge_rule.dart';
import 'seeded_random.dart';

/// Description of the next tile, shown in the "Next" preview.
class SpawnSpec {
  const SpawnSpec({required this.value, this.isStone = false, this.frozen = false});

  final int value;
  final bool isStone;
  final bool frozen;

  Map<String, dynamic> toJson() => {'v': value, 's': isStone, 'f': frozen};

  static SpawnSpec fromJson(Map<String, dynamic> json) => SpawnSpec(
        value: json['v'] as int,
        isStone: json['s'] as bool,
        frozen: json['f'] as bool,
      );

  @override
  bool operator ==(Object other) =>
      other is SpawnSpec &&
      other.value == value &&
      other.isStone == isStone &&
      other.frozen == frozen;

  @override
  int get hashCode => Object.hash(value, isStone, frozen);
}

/// Decides what appears next and where.
class SpawnRule {
  const SpawnRule({this.difficulty = const DifficultyCurve(), this.frozenTicks = 3});

  final DifficultyCurve difficulty;
  final int frozenTicks;

  SpawnSpec next(int level, SeededRandom rng, int maxOnBoard) {
    if (rng.chance(difficulty.stoneChance(level))) {
      return const SpawnSpec(value: 0, isStone: true);
    }
    final cap = math.max(4, maxOnBoard);
    final weights = Map.fromEntries(
      difficulty.spawnWeights(level).entries.where((e) => e.key <= cap),
    );
    final value = _weighted(weights, rng);
    final frozen = rng.chance(difficulty.frozenChance(level));
    return SpawnSpec(value: value, frozen: frozen);
  }

  Tile build(SpawnSpec spec, int id) => spec.isStone
      ? Tile(id: id, value: 0, kind: TileKind.stone)
      : Tile(id: id, value: spec.value, frozenTicks: spec.frozen ? frozenTicks : 0);

  /// A random free entry cell, or null when the entry is blocked (overflow).
  Pos? pickCell(List<Pos> entryCells, Board board, SeededRandom rng) {
    final free = entryCells.where((p) => board[p] == null).toList();
    if (free.isEmpty) return null;
    return rng.pick(free);
  }

  /// Fills the bottom of the board with [count] settled tiles that contain no
  /// mergeable group.
  void fillInitial(
    Board board,
    int count,
    SeededRandom rng,
    int Function() nextId,
    MergeRule mergeRule,
  ) {
    final maxPerColumn = math.max(1, board.size - 3);
    final heights = List<int>.filled(board.size, 0);
    var placed = 0;
    var guard = 0;
    while (placed < count && guard++ < 500) {
      final col = rng.nextInt(board.size);
      if (heights[col] >= maxPerColumn) continue;
      final pos = Pos(board.size - 1 - heights[col], col);
      final candidates = [2, 4, 8]..removeWhere((v) => v == 8 && rng.chance(0.7));
      rng.shuffle(candidates);
      for (final value in candidates) {
        board[pos] = Tile(id: nextId(), value: value);
        if (mergeRule.findGroups(board).isEmpty) break;
        board[pos] = null;
      }
      if (board[pos] != null) {
        heights[col]++;
        placed++;
      }
    }
  }

  int _weighted(Map<int, int> weights, SeededRandom rng) {
    final total = weights.values.fold(0, (a, b) => a + b);
    var roll = rng.nextInt(total);
    for (final e in weights.entries) {
      if (roll < e.value) return e.key;
      roll -= e.value;
    }
    return weights.keys.first;
  }
}
