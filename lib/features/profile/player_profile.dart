import '../../game/models/bonus_type.dart';
import '../../shared/theme/game_themes.dart';
import '../achievements/daily_quests.dart';
import '../settings/app_settings.dart';
import '../statistics/player_stats.dart';
import 'economy.dart';

/// Everything persisted about the player. Immutable; the profile controller
/// replaces it on every change and writes it to storage.
class PlayerProfile {
  const PlayerProfile({
    this.coins = Economy.startingCoins,
    this.bonuses = const {},
    this.bestScores = const {},
    this.stats = const PlayerStats(),
    this.claimedAchievements = const {},
    this.quests,
    this.lastLoginClaimDay,
    this.loginStreak = 0,
    this.dailyChallengeDay,
    this.dailyChallengeBest = 0,
    this.dailyGoalRewarded = false,
    this.adCoinsDay,
    this.adCoinsCount = 0,
    this.adsRemoved = false,
    this.ownedThemes = const {},
    this.settings = const AppSettings(),
  });

  factory PlayerProfile.fresh() => PlayerProfile(
        bonuses: {for (final t in BonusType.values) t: Economy.startingBonusCount},
      );

  final int coins;
  final Map<BonusType, int> bonuses;
  final Map<String, int> bestScores;
  final PlayerStats stats;
  final Set<String> claimedAchievements;
  final DailyQuests? quests;
  final int? lastLoginClaimDay;
  final int loginStreak;
  final int? dailyChallengeDay;
  final int dailyChallengeBest;
  final bool dailyGoalRewarded;
  final int? adCoinsDay;
  final int adCoinsCount;

  /// Reserved for a future "remove ads" purchase; disables interstitials.
  final bool adsRemoved;

  /// Bought themes; free ones are not listed.
  final Set<GameTheme> ownedThemes;
  final AppSettings settings;

  int bonusCount(BonusType t) => bonuses[t] ?? 0;
  int bestFor(String modeId) => bestScores[modeId] ?? 0;
  bool ownsTheme(GameTheme t) => t.isFree || ownedThemes.contains(t);

  PlayerProfile copyWith({
    int? coins,
    Map<BonusType, int>? bonuses,
    Map<String, int>? bestScores,
    PlayerStats? stats,
    Set<String>? claimedAchievements,
    DailyQuests? quests,
    int? lastLoginClaimDay,
    int? loginStreak,
    int? dailyChallengeDay,
    int? dailyChallengeBest,
    bool? dailyGoalRewarded,
    int? adCoinsDay,
    int? adCoinsCount,
    bool? adsRemoved,
    Set<GameTheme>? ownedThemes,
    AppSettings? settings,
  }) =>
      PlayerProfile(
        coins: coins ?? this.coins,
        bonuses: bonuses ?? this.bonuses,
        bestScores: bestScores ?? this.bestScores,
        stats: stats ?? this.stats,
        claimedAchievements: claimedAchievements ?? this.claimedAchievements,
        quests: quests ?? this.quests,
        lastLoginClaimDay: lastLoginClaimDay ?? this.lastLoginClaimDay,
        loginStreak: loginStreak ?? this.loginStreak,
        dailyChallengeDay: dailyChallengeDay ?? this.dailyChallengeDay,
        dailyChallengeBest: dailyChallengeBest ?? this.dailyChallengeBest,
        dailyGoalRewarded: dailyGoalRewarded ?? this.dailyGoalRewarded,
        adCoinsDay: adCoinsDay ?? this.adCoinsDay,
        adCoinsCount: adCoinsCount ?? this.adCoinsCount,
        adsRemoved: adsRemoved ?? this.adsRemoved,
        ownedThemes: ownedThemes ?? this.ownedThemes,
        settings: settings ?? this.settings,
      );

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'bonuses': {for (final e in bonuses.entries) e.key.name: e.value},
        'best': bestScores,
        'stats': stats.toJson(),
        'achievements': claimedAchievements.toList(),
        'quests': quests?.toJson(),
        'loginDay': lastLoginClaimDay,
        'streak': loginStreak,
        'dailyDay': dailyChallengeDay,
        'dailyBest': dailyChallengeBest,
        'dailyRewarded': dailyGoalRewarded,
        'adCoinsDay': adCoinsDay,
        'adCoinsCount': adCoinsCount,
        'adsRemoved': adsRemoved,
        'themes': [for (final t in ownedThemes) t.name],
        'settings': settings.toJson(),
      };

  static PlayerProfile fromJson(Map<String, dynamic> j) {
    final bonuses = j['bonuses'] as Map<String, dynamic>? ?? const {};
    final themes = {
      for (final name in (j['themes'] as List<dynamic>? ?? const []).cast<String>())
        ?GameTheme.values.asNameMap()[name],
    };
    var settings = AppSettings.fromJson(j['settings'] as Map<String, dynamic>?);
    if (!settings.theme.isFree && !themes.contains(settings.theme)) {
      settings = settings.copyWith(theme: GameTheme.classic);
    }
    return PlayerProfile(
      coins: j['coins'] as int? ?? Economy.startingCoins,
      bonuses: {for (final t in BonusType.values) t: bonuses[t.name] as int? ?? 0},
      bestScores: (j['best'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v as int)),
      stats: PlayerStats.fromJson(j['stats'] as Map<String, dynamic>? ?? const {}),
      claimedAchievements:
          {...(j['achievements'] as List<dynamic>? ?? const []).cast<String>()},
      quests: DailyQuests.fromJson(j['quests'] as Map<String, dynamic>?),
      lastLoginClaimDay: j['loginDay'] as int?,
      loginStreak: j['streak'] as int? ?? 0,
      dailyChallengeDay: j['dailyDay'] as int?,
      dailyChallengeBest: j['dailyBest'] as int? ?? 0,
      dailyGoalRewarded: j['dailyRewarded'] as bool? ?? false,
      adCoinsDay: j['adCoinsDay'] as int?,
      adCoinsCount: j['adCoinsCount'] as int? ?? 0,
      adsRemoved: j['adsRemoved'] as bool? ?? false,
      ownedThemes: themes,
      settings: settings,
    );
  }
}
