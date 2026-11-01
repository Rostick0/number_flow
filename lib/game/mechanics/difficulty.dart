import 'dart:math' as math;

/// Level-dependent tuning. See GAME_DESIGN.md §7.
class DifficultyCurve {
  const DifficultyCurve({
    this.baseTickMs = 1700,
    this.tickDecay = 0.92,
    this.minTickMs = 550,
    this.stonesFromLevel = 5,
    this.frozenFromLevel = 7,
  });

  final int baseTickMs;
  final double tickDecay;
  final int minTickMs;
  final int stonesFromLevel;
  final int frozenFromLevel;

  Duration tickInterval(int level) {
    final ms = baseTickMs * math.pow(tickDecay, level - 1);
    return Duration(milliseconds: math.max(minTickMs, ms.round()));
  }

  /// Spawn weights by value.
  Map<int, int> spawnWeights(int level) {
    if (level <= 2) return const {2: 70, 4: 30};
    if (level <= 4) return const {2: 55, 4: 35, 8: 10};
    if (level <= 9) return const {2: 45, 4: 35, 8: 15, 16: 5};
    return const {2: 40, 4: 33, 8: 18, 16: 7, 32: 2};
  }

  double stoneChance(int level) {
    if (level < stonesFromLevel) return 0;
    return math.min(0.10, 0.04 + 0.01 * (level - stonesFromLevel + 1));
  }

  double frozenChance(int level) {
    if (level < frozenFromLevel) return 0;
    return math.min(0.25, 0.10 + 0.05 * (level - frozenFromLevel));
  }
}
