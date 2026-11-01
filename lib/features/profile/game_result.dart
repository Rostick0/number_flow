import '../../game/models/session_stats.dart';

/// Outcome of a finished game, fed to the profile.
class GameResult {
  const GameResult({
    required this.modeId,
    required this.score,
    required this.stats,
    required this.duration,
  });

  final String modeId;
  final int score;
  final SessionStats stats;
  final Duration duration;
}

/// What the player got for a game; shown on the game-over screen.
class RewardSummary {
  const RewardSummary({
    required this.result,
    required this.coins,
    required this.newRecord,
    required this.previousBest,
    required this.dailyGoalReached,
    required this.unlockedAchievements,
    required this.completedQuests,
    this.doubled = false,
  });

  final GameResult result;

  /// Coins credited for the game (doubling credits the same amount again).
  final int coins;
  final bool newRecord;
  final int previousBest;
  final bool dailyGoalReached;
  final List<String> unlockedAchievements;
  final List<String> completedQuests;
  final bool doubled;

  RewardSummary markDoubled() => RewardSummary(
        result: result,
        coins: coins,
        newRecord: newRecord,
        previousBest: previousBest,
        dailyGoalReached: dailyGoalReached,
        unlockedAchievements: unlockedAchievements,
        completedQuests: completedQuests,
        doubled: true,
      );
}
