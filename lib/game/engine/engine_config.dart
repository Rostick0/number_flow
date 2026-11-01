/// Static parameters of one game. Produced by a GameMode.
class EngineConfig {
  const EngineConfig({
    required this.seed,
    this.size = 5,
    this.startLevel = 1,
    this.mergesPerLevel = 8,
    this.timeLimit,
    this.initialTiles = 6,
    this.bonusUsesPerGame = 3,
    this.slowMotionDuration = const Duration(seconds: 12),
    this.slowMotionFactor = 2,
    this.undoMaxTicks = 5,
  });

  final int seed;
  final int size;
  final int startLevel;
  final int mergesPerLevel;

  /// Null for endless modes.
  final Duration? timeLimit;
  final int initialTiles;
  final int bonusUsesPerGame;
  final Duration slowMotionDuration;
  final int slowMotionFactor;

  /// Undo is only offered while the last action is at most this many ticks old.
  final int undoMaxTicks;
}
