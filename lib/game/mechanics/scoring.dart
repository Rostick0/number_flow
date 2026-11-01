import 'dart:math' as math;

/// Points and combo maths. See GAME_DESIGN.md §6.
class ScoreCalculator {
  const ScoreCalculator({
    this.comboWindowTicks = 2,
    this.comboStep = 0.2,
    this.maxComboMultiplier = 3.0,
    this.stonePointsPerLevel = 10,
  });

  final int comboWindowTicks;
  final double comboStep;
  final double maxComboMultiplier;
  final int stonePointsPerLevel;

  double comboMultiplier(int combo) =>
      math.min(maxComboMultiplier, 1 + comboStep * math.max(0, combo - 1));

  int mergePoints({
    required int resultValue,
    required int groupSize,
    required int chain,
    required int combo,
  }) {
    final base = resultValue * groupSize;
    final bigGroup = 1 + 0.5 * math.max(0, groupSize - 3);
    return (base * bigGroup * chain * comboMultiplier(combo)).round();
  }

  int stonePoints(int level) => stonePointsPerLevel * level;
}
