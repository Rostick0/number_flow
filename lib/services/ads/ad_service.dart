import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_service.dart';
import 'interstitial_policy.dart';

/// The only API the game uses for ads. The game must work fully when
/// [rewardedReady] stays false forever (no network, no fill, tests).
abstract class AdService {
  ValueListenable<bool> get rewardedReady;

  Future<void> initialize();

  /// Shows a rewarded ad. Resolves to true only if the reward was earned.
  Future<bool> showRewarded();

  /// Counts a finished session for the interstitial frequency cap.
  void onGameFinished();

  /// Called between sessions only. Shows an interstitial if the frequency
  /// policy allows it; resolves after it is closed (or immediately).
  Future<void> maybeShowInterstitial({required bool adsRemoved});
}

/// Shared bookkeeping for the interstitial frequency cap.
abstract class PolicedAdService implements AdService {
  PolicedAdService(this._storage, {this.policy = const InterstitialPolicy()})
      : _counters = AdCounters.fromJson(_storage.readJson(StorageService.adsStateKey));

  final StorageService _storage;
  final InterstitialPolicy policy;
  AdCounters _counters;

  AdCounters get counters => _counters;

  @override
  void onGameFinished() => _save(_counters.gameFinished());

  @override
  Future<void> maybeShowInterstitial({required bool adsRemoved}) async {
    final now = DateTime.now();
    if (adsRemoved || !policy.shouldShow(_counters, now)) return;
    if (await showInterstitialNow()) _save(_counters.shown(now));
  }

  /// Returns true if an interstitial was actually displayed.
  @protected
  Future<bool> showInterstitialNow();

  void _save(AdCounters c) {
    _counters = c;
    _storage.writeJson(StorageService.adsStateKey, c.toJson());
  }
}

/// Used where the ad SDK is unavailable. Never shows anything.
class NoAdService extends PolicedAdService {
  NoAdService(super.storage);

  final _ready = ValueNotifier(false);

  @override
  ValueListenable<bool> get rewardedReady => _ready;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showRewarded() async => false;

  @override
  Future<bool> showInterstitialNow() async => false;
}

/// Overridden in `main()`.
final adServiceProvider = Provider<AdService>(
  (ref) => NoAdService(ref.read(storageProvider)),
);
