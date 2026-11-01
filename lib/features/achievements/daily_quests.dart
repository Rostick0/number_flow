import 'dart:math' as math;

import '../../game/mechanics/seeded_random.dart';
import '../profile/game_result.dart';

enum QuestAggregation { sum, best }

/// A quest template; [amount] extracts this game's contribution.
class QuestTemplate {
  const QuestTemplate({
    required this.id,
    required this.title,
    required this.target,
    required this.reward,
    required this.aggregation,
    required this.amount,
  });

  final String id;
  final String title;
  final int target;
  final int reward;
  final QuestAggregation aggregation;
  final int Function(GameResult r) amount;
}

final List<QuestTemplate> questPool = [
  QuestTemplate(
    id: 'merges_30',
    title: 'Сделай 30 слияний',
    target: 30,
    reward: 25,
    aggregation: QuestAggregation.sum,
    amount: (r) => r.stats.merges,
  ),
  QuestTemplate(
    id: 'merges_60',
    title: 'Сделай 60 слияний',
    target: 60,
    reward: 40,
    aggregation: QuestAggregation.sum,
    amount: (r) => r.stats.merges,
  ),
  QuestTemplate(
    id: 'games_3',
    title: 'Сыграй 3 партии',
    target: 3,
    reward: 30,
    aggregation: QuestAggregation.sum,
    amount: (r) => 1,
  ),
  QuestTemplate(
    id: 'score_1500',
    title: 'Набери 1500 очков за партию',
    target: 1500,
    reward: 35,
    aggregation: QuestAggregation.best,
    amount: (r) => r.score,
  ),
  QuestTemplate(
    id: 'score_3000',
    title: 'Набери 3000 очков за партию',
    target: 3000,
    reward: 50,
    aggregation: QuestAggregation.best,
    amount: (r) => r.score,
  ),
  QuestTemplate(
    id: 'tile_64',
    title: 'Получи блок 64',
    target: 64,
    reward: 35,
    aggregation: QuestAggregation.best,
    amount: (r) => r.stats.maxValue,
  ),
  QuestTemplate(
    id: 'tile_128',
    title: 'Получи блок 128',
    target: 128,
    reward: 50,
    aggregation: QuestAggregation.best,
    amount: (r) => r.stats.maxValue,
  ),
  QuestTemplate(
    id: 'chain_2',
    title: 'Сделай цепочку из 2 слияний',
    target: 2,
    reward: 30,
    aggregation: QuestAggregation.best,
    amount: (r) => r.stats.maxChain,
  ),
  QuestTemplate(
    id: 'combo_4',
    title: 'Достигни комбо ×4',
    target: 4,
    reward: 35,
    aggregation: QuestAggregation.best,
    amount: (r) => r.stats.maxCombo,
  ),
  QuestTemplate(
    id: 'stones_5',
    title: 'Разбей 5 камней',
    target: 5,
    reward: 40,
    aggregation: QuestAggregation.sum,
    amount: (r) => r.stats.stonesDestroyed,
  ),
  QuestTemplate(
    id: 'bonus_1',
    title: 'Используй любой бонус',
    target: 1,
    reward: 20,
    aggregation: QuestAggregation.sum,
    amount: (r) => r.stats.bonusesUsed,
  ),
];

QuestTemplate? questTemplate(String id) {
  for (final q in questPool) {
    if (q.id == id) return q;
  }
  return null;
}

class QuestProgress {
  const QuestProgress({required this.id, this.progress = 0, this.claimed = false});

  final String id;
  final int progress;
  final bool claimed;

  QuestTemplate get template => questTemplate(id)!;
  bool get isComplete => progress >= template.target;
  bool get canClaim => isComplete && !claimed;

  QuestProgress withResult(GameResult r) {
    final t = template;
    final amount = t.amount(r);
    final next = t.aggregation == QuestAggregation.sum
        ? progress + amount
        : math.max(progress, amount);
    return QuestProgress(id: id, progress: math.min(next, t.target), claimed: claimed);
  }

  QuestProgress claim() => QuestProgress(id: id, progress: progress, claimed: true);

  Map<String, dynamic> toJson() => {'id': id, 'p': progress, 'c': claimed};

  static QuestProgress fromJson(Map<String, dynamic> j) => QuestProgress(
        id: j['id'] as String,
        progress: j['p'] as int,
        claimed: j['c'] as bool,
      );
}

class DailyQuests {
  const DailyQuests({required this.dayKey, required this.quests});

  final int dayKey;
  final List<QuestProgress> quests;

  /// Three distinct quests picked deterministically for the day.
  factory DailyQuests.forDay(int dayKey) {
    final ids = [for (final q in questPool) q.id];
    SeededRandom(dayKey * 7919).shuffle(ids);
    return DailyQuests(
      dayKey: dayKey,
      quests: [for (final id in ids.take(3)) QuestProgress(id: id)],
    );
  }

  int get claimable => quests.where((q) => q.canClaim).length;

  DailyQuests withResult(GameResult r) =>
      DailyQuests(dayKey: dayKey, quests: [for (final q in quests) q.withResult(r)]);

  Map<String, dynamic> toJson() => {
        'day': dayKey,
        'quests': [for (final q in quests) q.toJson()],
      };

  static DailyQuests? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final quests = [
      for (final q in j['quests'] as List<dynamic>)
        QuestProgress.fromJson(q as Map<String, dynamic>),
    ];
    if (quests.any((q) => questTemplate(q.id) == null)) return null;
    return DailyQuests(dayKey: j['day'] as int, quests: quests);
  }
}
