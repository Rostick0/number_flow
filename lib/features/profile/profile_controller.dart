import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/day_key.dart';
import '../../game/models/bonus_type.dart';
import '../../game/modes/mode_registry.dart';
import '../../services/storage/storage_service.dart';
import '../achievements/achievement.dart';
import '../achievements/daily_quests.dart';
import '../settings/app_settings.dart';
import 'economy.dart';
import 'game_result.dart';
import 'player_profile.dart';

/// Single owner of the persisted [PlayerProfile]. Every mutation is written
/// to storage immediately, so progress survives an app kill at any moment.
class ProfileController extends Notifier<PlayerProfile> {
  StorageService get _storage => ref.read(storageProvider);
  int get _today => dayKeyOf(ref.read(clockProvider)());

  @override
  PlayerProfile build() {
    final json = _storage.readJson(StorageService.profileKey);
    final loaded = _parse(json);
    final rolled = _rollDay(loaded);
    if (json == null || !identical(rolled, loaded)) {
      _storage.writeJson(StorageService.profileKey, rolled.toJson());
    }
    return rolled;
  }

  static PlayerProfile _parse(Map<String, dynamic>? json) {
    if (json == null) return PlayerProfile.fresh();
    try {
      return PlayerProfile.fromJson(json);
    } catch (e) {
      debugPrint('Profile could not be read, starting fresh: $e');
      return PlayerProfile.fresh();
    }
  }

  void _commit(PlayerProfile next) {
    state = next;
    _storage.writeJson(StorageService.profileKey, next.toJson());
  }

  /// Regenerates day-bound content when the calendar day changed.
  PlayerProfile _rollDay(PlayerProfile p) {
    final today = _today;
    if (p.quests?.dayKey == today && p.dailyChallengeDay == today) return p;
    return p.copyWith(
      quests: p.quests?.dayKey == today ? p.quests : DailyQuests.forDay(today),
      dailyChallengeDay: today,
      dailyChallengeBest: p.dailyChallengeDay == today ? p.dailyChallengeBest : 0,
      dailyGoalRewarded: p.dailyChallengeDay == today ? p.dailyGoalRewarded : false,
    );
  }

  /// Call when the app returns to the foreground or a screen opens.
  void refreshDay() {
    final rolled = _rollDay(state);
    if (!identical(rolled, state)) _commit(rolled);
  }

  // ------------------------------------------------------------------ coins

  void addCoins(int amount) => _commit(state.copyWith(coins: state.coins + amount));

  bool trySpend(int amount) {
    if (state.coins < amount) return false;
    _commit(state.copyWith(coins: state.coins - amount));
    return true;
  }

  int get adCoinsLeftToday => state.adCoinsDay == _today
      ? math.max(0, Economy.maxAdCoinsPerDay - state.adCoinsCount)
      : Economy.maxAdCoinsPerDay;

  void grantAdCoins() {
    final today = _today;
    final count = state.adCoinsDay == today ? state.adCoinsCount : 0;
    _commit(state.copyWith(
      coins: state.coins + Economy.adCoins,
      adCoinsDay: today,
      adCoinsCount: count + 1,
    ));
  }

  // ---------------------------------------------------------------- bonuses

  void addBonus(BonusType type, [int amount = 1]) => _commit(state.copyWith(
        bonuses: {...state.bonuses, type: state.bonusCount(type) + amount},
      ));

  bool buyBonus(BonusType type) {
    if (state.coins < type.price) return false;
    _commit(state.copyWith(
      coins: state.coins - type.price,
      bonuses: {...state.bonuses, type: state.bonusCount(type) + 1},
    ));
    return true;
  }

  bool consumeBonus(BonusType type) {
    if (state.bonusCount(type) <= 0) return false;
    _commit(state.copyWith(
      bonuses: {...state.bonuses, type: state.bonusCount(type) - 1},
    ));
    return true;
  }

  // ------------------------------------------------------------ daily login

  bool get canClaimLogin => state.lastLoginClaimDay != _today;

  /// Streak day the next claim would count as (1..∞).
  int get nextLoginStreak {
    final last = state.lastLoginClaimDay;
    if (last == null) return 1;
    return daysBetween(last, _today) == 1 ? state.loginStreak + 1 : 1;
  }

  int claimLogin() {
    if (!canClaimLogin) return 0;
    final streak = nextLoginStreak;
    final reward = Economy.loginReward(streak);
    _commit(state.copyWith(
      coins: state.coins + reward,
      lastLoginClaimDay: _today,
      loginStreak: streak,
    ));
    return reward;
  }

  // --------------------------------------------------- quests, achievements

  int claimQuest(String id) {
    refreshDay();
    final quests = state.quests;
    if (quests == null) return 0;
    final quest = quests.quests.where((q) => q.id == id).firstOrNull;
    if (quest == null || !quest.canClaim) return 0;
    _commit(state.copyWith(
      coins: state.coins + quest.template.reward,
      quests: DailyQuests(
        dayKey: quests.dayKey,
        quests: [for (final q in quests.quests) q.id == id ? q.claim() : q],
      ),
    ));
    return quest.template.reward;
  }

  int claimAchievement(String id) {
    final a = achievements.where((a) => a.id == id).firstOrNull;
    if (a == null || !a.isUnlocked(state) || state.claimedAchievements.contains(id)) {
      return 0;
    }
    _commit(state.copyWith(
      coins: state.coins + a.reward,
      claimedAchievements: {...state.claimedAchievements, id},
    ));
    return a.reward;
  }

  // ------------------------------------------------------------ game result

  RewardSummary recordGame(GameResult r) {
    refreshDay();
    final before = state;
    final now = ref.read(clockProvider)();
    final previousBest = before.bestFor(r.modeId);
    final newRecord = r.score > previousBest && r.score > 0;

    final isDaily = r.modeId == 'daily';
    final target = ModeRegistry.byId(r.modeId).targetScore(now);
    final dailyGoalReached =
        isDaily && target != null && r.score >= target && !before.dailyGoalRewarded;

    final coins = Economy.coinsForGame(r.score, newRecord: newRecord) +
        (dailyGoalReached ? Economy.dailyGoalReward : 0);

    final oldQuests = before.quests ?? DailyQuests.forDay(_today);
    final newQuests = oldQuests.withResult(r);

    var after = before.copyWith(
      coins: before.coins + coins,
      bestScores: {
        ...before.bestScores,
        r.modeId: math.max(previousBest, r.score),
      },
      stats: before.stats.withGame(
        modeId: r.modeId,
        score: r.score,
        session: r.stats,
        duration: r.duration,
        dailyCompletedNow: dailyGoalReached,
      ),
      quests: newQuests,
    );
    if (isDaily) {
      after = after.copyWith(
        dailyChallengeBest: math.max(before.dailyChallengeBest, r.score),
        dailyGoalRewarded: before.dailyGoalRewarded || dailyGoalReached,
      );
    }
    _commit(after);

    return RewardSummary(
      result: r,
      coins: coins,
      newRecord: newRecord,
      previousBest: previousBest,
      dailyGoalReached: dailyGoalReached,
      unlockedAchievements: [
        for (final a in achievements)
          if (!a.isUnlocked(before) && a.isUnlocked(after)) a.title,
      ],
      completedQuests: [
        for (var i = 0; i < newQuests.quests.length; i++)
          if (newQuests.quests[i].isComplete && !oldQuests.quests[i].isComplete)
            newQuests.quests[i].template.title,
      ],
    );
  }

  // --------------------------------------------------------------- settings

  void updateSettings(AppSettings Function(AppSettings s) change) =>
      _commit(state.copyWith(settings: change(state.settings)));

  void resetProgress() {
    final settings = state.settings;
    _commit(_rollDay(PlayerProfile.fresh()).copyWith(settings: settings));
  }
}

/// Quests and achievements whose rewards wait to be claimed.
int claimableRewards(PlayerProfile p) =>
    (p.quests?.claimable ?? 0) +
    achievements
        .where((a) => a.isUnlocked(p) && !p.claimedAchievements.contains(a.id))
        .length;

final profileProvider =
    NotifierProvider<ProfileController, PlayerProfile>(ProfileController.new);
