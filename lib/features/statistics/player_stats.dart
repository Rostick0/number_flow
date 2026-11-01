import 'dart:math' as math;

import '../../game/models/session_stats.dart';

/// Lifetime statistics.
class PlayerStats {
  const PlayerStats({
    this.gamesPlayed = 0,
    this.totalScore = 0,
    this.totalMerges = 0,
    this.totalMergedTiles = 0,
    this.maxTile = 0,
    this.bestChain = 0,
    this.bestCombo = 0,
    this.stonesDestroyed = 0,
    this.bonusesUsed = 0,
    this.playTimeSeconds = 0,
    this.dailyCompleted = 0,
    this.gamesByMode = const {},
  });

  final int gamesPlayed;
  final int totalScore;
  final int totalMerges;
  final int totalMergedTiles;
  final int maxTile;
  final int bestChain;
  final int bestCombo;
  final int stonesDestroyed;
  final int bonusesUsed;
  final int playTimeSeconds;
  final int dailyCompleted;
  final Map<String, int> gamesByMode;

  int get averageScore => gamesPlayed == 0 ? 0 : totalScore ~/ gamesPlayed;

  PlayerStats withGame({
    required String modeId,
    required int score,
    required SessionStats session,
    required Duration duration,
    bool dailyCompletedNow = false,
  }) =>
      PlayerStats(
        gamesPlayed: gamesPlayed + 1,
        totalScore: totalScore + score,
        totalMerges: totalMerges + session.merges,
        totalMergedTiles: totalMergedTiles + session.mergedTiles,
        maxTile: math.max(maxTile, session.maxValue),
        bestChain: math.max(bestChain, session.maxChain),
        bestCombo: math.max(bestCombo, session.maxCombo),
        stonesDestroyed: stonesDestroyed + session.stonesDestroyed,
        bonusesUsed: bonusesUsed + session.bonusesUsed,
        playTimeSeconds: playTimeSeconds + duration.inSeconds,
        dailyCompleted: dailyCompleted + (dailyCompletedNow ? 1 : 0),
        gamesByMode: {...gamesByMode, modeId: (gamesByMode[modeId] ?? 0) + 1},
      );

  Map<String, dynamic> toJson() => {
        'games': gamesPlayed,
        'score': totalScore,
        'merges': totalMerges,
        'mergedTiles': totalMergedTiles,
        'maxTile': maxTile,
        'chain': bestChain,
        'combo': bestCombo,
        'stones': stonesDestroyed,
        'bonuses': bonusesUsed,
        'time': playTimeSeconds,
        'daily': dailyCompleted,
        'byMode': gamesByMode,
      };

  static PlayerStats fromJson(Map<String, dynamic> j) => PlayerStats(
        gamesPlayed: j['games'] as int? ?? 0,
        totalScore: j['score'] as int? ?? 0,
        totalMerges: j['merges'] as int? ?? 0,
        totalMergedTiles: j['mergedTiles'] as int? ?? 0,
        maxTile: j['maxTile'] as int? ?? 0,
        bestChain: j['chain'] as int? ?? 0,
        bestCombo: j['combo'] as int? ?? 0,
        stonesDestroyed: j['stones'] as int? ?? 0,
        bonusesUsed: j['bonuses'] as int? ?? 0,
        playTimeSeconds: j['time'] as int? ?? 0,
        dailyCompleted: j['daily'] as int? ?? 0,
        gamesByMode: (j['byMode'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v as int)),
      );
}
