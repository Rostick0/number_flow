import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

import 'ad_service.dart';

/// Ad unit ids. The demo ids serve Yandex test ads; replace them with the
/// production ids from the Yandex Advertising Network partner interface.
class AdUnits {
  static const rewarded = String.fromEnvironment(
    'YANDEX_REWARDED_ID',
    defaultValue: 'demo-rewarded-yandex',
  );
  static const interstitial = String.fromEnvironment(
    'YANDEX_INTERSTITIAL_ID',
    defaultValue: 'demo-interstitial-yandex',
  );
}

/// Yandex Mobile Ads implementation. Every SDK call is guarded: a failure
/// only means "no ad", never a broken game.
class YandexAdService extends PolicedAdService {
  YandexAdService(super.storage);

  final _rewardedReady = ValueNotifier(false);
  RewardedAdLoader? _rewardedLoader;
  InterstitialAdLoader? _interstitialLoader;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _initialized = false;
  int _rewardedRetry = 0;
  int _interstitialRetry = 0;

  @override
  ValueListenable<bool> get rewardedReady => _rewardedReady;

  @override
  Future<void> initialize() async {
    try {
      await YandexAds.initialize().timeout(const Duration(seconds: 15));
      _rewardedLoader = RewardedAdLoader();
      _interstitialLoader = InterstitialAdLoader();
      _initialized = true;
      unawaited(_loadRewarded());
      unawaited(_loadInterstitial());
    } catch (e) {
      debugPrint('Yandex Ads unavailable: $e');
    }
  }

  Future<void> _loadRewarded() async {
    final loader = _rewardedLoader;
    if (loader == null) return;
    try {
      _rewarded = await loader.loadAd(
        adRequest: const AdRequest(adUnitId: AdUnits.rewarded),
      );
      _rewardedRetry = 0;
      _rewardedReady.value = true;
    } catch (e) {
      _rewardedReady.value = false;
      _scheduleRetry(_rewardedRetry++, _loadRewarded);
    }
  }

  Future<void> _loadInterstitial() async {
    final loader = _interstitialLoader;
    if (loader == null) return;
    try {
      _interstitial = await loader.loadAd(
        adRequest: const AdRequest(adUnitId: AdUnits.interstitial),
      );
      _interstitialRetry = 0;
    } catch (e) {
      _scheduleRetry(_interstitialRetry++, _loadInterstitial);
    }
  }

  void _scheduleRetry(int attempt, Future<void> Function() load) {
    final seconds = (10 * (1 << attempt.clamp(0, 5))).clamp(10, 300);
    Timer(Duration(seconds: seconds), load);
  }

  @override
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (!_initialized || ad == null) return false;
    _rewarded = null;
    _rewardedReady.value = false;
    var earned = false;
    final closed = Completer<void>();
    try {
      await ad.setAdEventListener(
        eventListener: RewardedAdEventListener(
          onRewarded: (_) => earned = true,
          onAdDismissed: () {
            if (!closed.isCompleted) closed.complete();
          },
          onAdFailedToShow: (_) {
            if (!closed.isCompleted) closed.complete();
          },
        ),
      );
      await ad.show();
      await closed.future.timeout(const Duration(minutes: 3));
    } catch (e) {
      debugPrint('Rewarded ad failed: $e');
    } finally {
      unawaited(ad.destroy());
      unawaited(_loadRewarded());
    }
    return earned;
  }

  @override
  Future<bool> showInterstitialNow() async {
    final ad = _interstitial;
    if (!_initialized || ad == null) return false;
    _interstitial = null;
    var shown = false;
    final closed = Completer<void>();
    try {
      await ad.setAdEventListener(
        eventListener: InterstitialAdEventListener(
          onAdShown: () => shown = true,
          onAdDismissed: () {
            if (!closed.isCompleted) closed.complete();
          },
          onAdFailedToShow: (_) {
            if (!closed.isCompleted) closed.complete();
          },
        ),
      );
      await ad.show();
      await closed.future.timeout(const Duration(minutes: 2));
    } catch (e) {
      debugPrint('Interstitial failed: $e');
    } finally {
      unawaited(ad.destroy());
      unawaited(_loadInterstitial());
    }
    return shown;
  }
}
