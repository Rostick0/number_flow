import 'dart:math' as math;

/// Coin rules. See GAME_DESIGN.md §10.
class Economy {
  static const startingCoins = 100;
  static const startingBonusCount = 2;
  static const maxCoinsPerGame = 150;
  static const recordBonus = 20;
  static const dailyGoalReward = 60;
  static const adCoins = 40;
  static const maxAdCoinsPerDay = 5;
  static const loginRewards = [20, 30, 40, 50, 60, 80, 120];

  static int coinsForGame(int score, {required bool newRecord}) =>
      math.min(maxCoinsPerGame, score ~/ 100) + (newRecord ? recordBonus : 0);

  /// Reward for the [streakDay]-th consecutive day (1-based, cycles weekly).
  static int loginReward(int streakDay) =>
      loginRewards[(streakDay - 1) % loginRewards.length];
}
