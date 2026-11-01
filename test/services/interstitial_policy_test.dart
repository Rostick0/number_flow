import 'package:flutter_test/flutter_test.dart';
import 'package:number_flow/services/ads/interstitial_policy.dart';

void main() {
  const policy = InterstitialPolicy();
  final now = DateTime(2026, 11, 1, 12);

  AdCounters games(int n, {AdCounters from = const AdCounters()}) {
    var c = from;
    for (var i = 0; i < n; i++) {
      c = c.gameFinished();
    }
    return c;
  }

  test('no interstitials during the first games', () {
    expect(policy.shouldShow(games(2), now), isFalse);
    expect(policy.shouldShow(games(3), now), isTrue);
  });

  test('requires several games between interstitials', () {
    final shown = games(3).shown(now);
    final later = now.add(const Duration(hours: 1));
    expect(policy.shouldShow(games(2, from: shown), later), isFalse);
    expect(policy.shouldShow(games(3, from: shown), later), isTrue);
  });

  test('requires a minimum interval between interstitials', () {
    final c = games(3, from: games(3).shown(now));
    expect(policy.shouldShow(c, now.add(const Duration(minutes: 1))), isFalse);
    expect(policy.shouldShow(c, now.add(const Duration(minutes: 3))), isTrue);
  });

  test('counters survive serialization', () {
    final c = games(5).shown(now).gameFinished();
    final restored = AdCounters.fromJson(c.toJson());
    expect(restored.totalGames, 6);
    expect(restored.gamesSinceLast, 1);
    expect(restored.lastShownAt, now);
  });
}
