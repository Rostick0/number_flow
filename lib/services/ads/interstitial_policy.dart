/// Frequency cap for interstitials between game sessions.
class InterstitialPolicy {
  const InterstitialPolicy({
    this.graceGames = 2,
    this.minGamesBetween = 3,
    this.minInterval = const Duration(minutes: 3),
  });

  /// No interstitials during the player's first games.
  final int graceGames;
  final int minGamesBetween;
  final Duration minInterval;

  bool shouldShow(AdCounters c, DateTime now) {
    if (c.totalGames <= graceGames) return false;
    if (c.gamesSinceLast < minGamesBetween) return false;
    final last = c.lastShownAt;
    return last == null || now.difference(last) >= minInterval;
  }
}

class AdCounters {
  const AdCounters({this.totalGames = 0, this.gamesSinceLast = 0, this.lastShownAt});

  final int totalGames;
  final int gamesSinceLast;
  final DateTime? lastShownAt;

  AdCounters gameFinished() => AdCounters(
        totalGames: totalGames + 1,
        gamesSinceLast: gamesSinceLast + 1,
        lastShownAt: lastShownAt,
      );

  AdCounters shown(DateTime now) =>
      AdCounters(totalGames: totalGames, gamesSinceLast: 0, lastShownAt: now);

  Map<String, dynamic> toJson() => {
        'total': totalGames,
        'since': gamesSinceLast,
        'last': lastShownAt?.millisecondsSinceEpoch,
      };

  static AdCounters fromJson(Map<String, dynamic>? j) {
    if (j == null) return const AdCounters();
    final last = j['last'] as int?;
    return AdCounters(
      totalGames: j['total'] as int? ?? 0,
      gamesSinceLast: j['since'] as int? ?? 0,
      lastShownAt: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
    );
  }
}
