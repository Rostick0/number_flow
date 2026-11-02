import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_flow/core/clock.dart';
import 'package:number_flow/features/settings/app_settings.dart';
import 'package:number_flow/features/gameplay/saved_game.dart';
import 'package:number_flow/features/profile/economy.dart';
import 'package:number_flow/features/profile/game_result.dart';
import 'package:number_flow/features/profile/player_profile.dart';
import 'package:number_flow/features/profile/profile_controller.dart';
import 'package:number_flow/game/engine/game_engine.dart';
import 'package:number_flow/game/models/bonus_type.dart';
import 'package:number_flow/game/models/session_stats.dart';
import 'package:number_flow/game/modes/game_mode.dart';
import 'package:number_flow/services/storage/storage_service.dart';
import 'package:number_flow/shared/theme/game_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulates an app process: fresh SharedPreferences instance over the
/// given persisted values, fresh providers.
class _App {
  _App._(this.storage, this.container);

  final StorageService storage;
  final ProviderContainer container;
  DateTime now = DateTime(2026, 11, 1, 12);

  static Future<_App> launch([Map<String, Object> persisted = const {}]) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues(persisted);
    final storage = await StorageService.open();
    late _App app;
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(storage),
      clockProvider.overrideWithValue(() => app.now),
    ]);
    app = _App._(storage, container);
    return app;
  }

  ProfileController get profile => container.read(profileProvider.notifier);

  /// Everything currently persisted, to "restart" with.
  Future<Map<String, Object>> persisted() async {
    final prefs = await SharedPreferences.getInstance();
    return {for (final k in prefs.getKeys()) k: prefs.get(k)!};
  }
}

GameResult _result(String mode, int score, {int merges = 10, int maxValue = 32}) => GameResult(
      modeId: mode,
      score: score,
      stats: SessionStats(merges: merges, mergedTiles: merges * 3, maxValue: maxValue, maxChain: 2),
      duration: const Duration(minutes: 2),
    );

void main() {
  test('new player starts with coins and bonuses', () async {
    final app = await _App.launch();
    final p = app.container.read(profileProvider);
    expect(p.coins, Economy.startingCoins);
    for (final t in BonusType.values) {
      expect(p.bonusCount(t), Economy.startingBonusCount);
    }
    expect(p.quests!.quests, hasLength(3));
  });

  test('records, coins and stats survive an app restart', () async {
    final app = await _App.launch();
    final summary = app.profile.recordGame(_result('classic', 2500));
    expect(summary.newRecord, isTrue);
    expect(summary.coins, 25 + Economy.recordBonus);

    final restarted = await _App.launch(await app.persisted());
    final p = restarted.container.read(profileProvider);
    expect(p.bestFor('classic'), 2500);
    expect(p.coins, Economy.startingCoins + summary.coins);
    expect(p.stats.gamesPlayed, 1);
    expect(p.stats.totalMerges, 10);
    expect(p.stats.maxTile, 32);
  });

  test('themes are bought once, switch on purchase and survive a restart', () async {
    final app = await _App.launch();
    expect(app.container.read(profileProvider).settings.theme, GameTheme.classic);
    expect(app.profile.selectTheme(GameTheme.neon), isFalse);
    expect(app.profile.buyTheme(GameTheme.neon), isFalse, reason: 'not enough coins');

    app.profile.addCoins(GameTheme.neon.price);
    final before = app.container.read(profileProvider).coins;
    expect(app.profile.buyTheme(GameTheme.neon), isTrue);
    expect(app.profile.buyTheme(GameTheme.neon), isFalse, reason: 'already owned');
    var p = app.container.read(profileProvider);
    expect(p.coins, before - GameTheme.neon.price);
    expect(p.settings.theme, GameTheme.neon);

    expect(app.profile.selectTheme(GameTheme.classic), isTrue);
    final restarted = await _App.launch(await app.persisted());
    p = restarted.container.read(profileProvider);
    expect(p.ownsTheme(GameTheme.neon), isTrue);
    expect(p.ownsTheme(GameTheme.night), isFalse);
    expect(p.settings.theme, GameTheme.classic);
    expect(restarted.profile.selectTheme(GameTheme.neon), isTrue);
  });

  test('progress reset takes bought themes back', () async {
    final app = await _App.launch();
    app.profile.addCoins(GameTheme.night.price);
    app.profile.buyTheme(GameTheme.night);
    app.profile.resetProgress();
    final p = app.container.read(profileProvider);
    expect(p.ownsTheme(GameTheme.night), isFalse);
    expect(p.settings.theme, GameTheme.classic);
  });

  test('a saved theme that is not owned falls back to classic', () async {
    final app = await _App.launch();
    final json = app.container.read(profileProvider).toJson()
      ..['settings'] = const AppSettings(theme: GameTheme.neon).toJson();
    final p = PlayerProfile.fromJson(json);
    expect(p.settings.theme, GameTheme.classic);
  });

  test('an unknown saved theme falls back to classic', () {
    final s = AppSettings.fromJson({'theme': 'removed_theme'});
    expect(s.theme, GameTheme.classic);
    expect(AppSettings.fromJson({}).theme, GameTheme.classic);
  });

  test('a lower score does not replace the record', () async {
    final app = await _App.launch();
    app.profile.recordGame(_result('classic', 3000));
    final s = app.profile.recordGame(_result('classic', 1000));
    expect(s.newRecord, isFalse);
    expect(s.previousBest, 3000);
    expect(app.container.read(profileProvider).bestFor('classic'), 3000);
  });

  test('coins per game are capped', () async {
    final app = await _App.launch();
    app.profile.recordGame(_result('classic', 10));
    final s = app.profile.recordGame(_result('classic', 1000000));
    expect(s.coins, Economy.maxCoinsPerGame + Economy.recordBonus);
  });

  test('bonuses can be bought, consumed and never go negative', () async {
    final app = await _App.launch();
    final c = app.profile;
    expect(c.buyBonus(BonusType.undo), isTrue);
    expect(app.container.read(profileProvider).bonusCount(BonusType.undo), 3);
    expect(app.container.read(profileProvider).coins, Economy.startingCoins - BonusType.undo.price);
    expect(c.buyBonus(BonusType.doubleMerge), isFalse); // 40 coins left
    for (var i = 0; i < 3; i++) {
      expect(c.consumeBonus(BonusType.undo), isTrue);
    }
    expect(c.consumeBonus(BonusType.undo), isFalse);
  });

  test('login streak grows on consecutive days and resets after a gap', () async {
    final app = await _App.launch();
    final c = app.profile;
    expect(c.claimLogin(), Economy.loginRewards[0]);
    expect(c.canClaimLogin, isFalse);
    expect(c.claimLogin(), 0);
    app.now = DateTime(2026, 11, 2, 9);
    expect(c.claimLogin(), Economy.loginRewards[1]);
    app.now = DateTime(2026, 11, 5, 9);
    expect(c.nextLoginStreak, 1);
    expect(c.claimLogin(), Economy.loginRewards[0]);
  });

  test('quests progress from games and pay out once', () async {
    final app = await _App.launch();
    final quests = app.container.read(profileProvider).quests!.quests;
    for (var i = 0; i < 4; i++) {
      app.profile.recordGame(_result('classic', 4000, merges: 70, maxValue: 256));
    }
    final p = app.container.read(profileProvider);
    final claimable = p.quests!.quests.where((q) => q.canClaim).toList();
    // Every quest in the pool is satisfiable by these games except
    // combo/stones/bonus ones, which the results did not include.
    expect(claimable, isNotEmpty);
    final q = claimable.first;
    final before = p.coins;
    expect(app.profile.claimQuest(q.id), q.template.reward);
    expect(app.container.read(profileProvider).coins, before + q.template.reward);
    expect(app.profile.claimQuest(q.id), 0);
    expect(quests.map((q) => q.id), p.quests!.quests.map((q) => q.id));
  });

  test('quests are replaced on a new day', () async {
    final app = await _App.launch();
    final today = app.container.read(profileProvider).quests!;
    app.now = DateTime(2026, 11, 2, 9);
    app.profile.refreshDay();
    final tomorrow = app.container.read(profileProvider).quests!;
    expect(tomorrow.dayKey, isNot(today.dayKey));
  });

  test('daily goal reward is granted once per day', () async {
    final app = await _App.launch();
    final target = const DailyChallengeMode().targetScore(app.now);
    final first = app.profile.recordGame(_result('daily', target));
    expect(first.dailyGoalReached, isTrue);
    final second = app.profile.recordGame(_result('daily', target + 500));
    expect(second.dailyGoalReached, isFalse);
    expect(app.container.read(profileProvider).stats.dailyCompleted, 1);
    app.now = DateTime(2026, 11, 2, 9);
    final nextTarget = const DailyChallengeMode().targetScore(app.now);
    expect(app.profile.recordGame(_result('daily', nextTarget)).dailyGoalReached, isTrue);
  });

  test('achievements unlock from stats and are claimed once', () async {
    final app = await _App.launch();
    app.profile.recordGame(_result('classic', 2500));
    expect(claimableRewards(app.container.read(profileProvider)), greaterThan(0));
    final coins = app.container.read(profileProvider).coins;
    expect(app.profile.claimAchievement('first_merge'), 20);
    expect(app.profile.claimAchievement('first_merge'), 0);
    expect(app.profile.claimAchievement('tile_1024'), 0);
    expect(app.container.read(profileProvider).coins, coins + 20);
  });

  test('unfinished game is saved and restored after restart', () async {
    final app = await _App.launch();
    const mode = ClassicMode();
    final engine = GameEngine(mode.config(1234));
    for (var i = 0; i < 6; i++) {
      engine.tick();
    }
    app.container.read(savedGameRepositoryProvider).save(mode.id, 1234, engine);

    final restarted = await _App.launch(await app.persisted());
    final saved = restarted.container.read(savedGameRepositoryProvider).load()!;
    final restored = saved.restore();
    expect(restored.cells, engine.cells);
    expect(restored.score, engine.score);
    expect(restored.tickCount, engine.tickCount);
  });

  test('a daily challenge save expires the next day', () async {
    final app = await _App.launch();
    const mode = DailyChallengeMode();
    final seed = mode.newSeed(app.now, math.Random());
    app.container.read(savedGameRepositoryProvider).save(mode.id, seed, GameEngine(mode.config(seed)));
    expect(app.container.read(savedGameRepositoryProvider).load(), isNotNull);
    app.now = DateTime(2026, 11, 2, 9);
    expect(app.container.read(savedGameRepositoryProvider).load(), isNull);
  });

  test('corrupted storage falls back to a fresh profile', () async {
    final app = await _App.launch({StorageService.profileKey: '{not json'});
    expect(app.container.read(profileProvider).coins, Economy.startingCoins);
  });
}
