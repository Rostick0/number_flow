import '../profile/player_profile.dart';

/// A lifetime goal. Progress is read from the profile, so achievements need
/// no bookkeeping of their own beyond "claimed".
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.target,
    required this.metric,
  });

  final String id;
  final String title;
  final String description;
  final int reward;
  final int target;
  final int Function(PlayerProfile p) metric;

  int progress(PlayerProfile p) => metric(p).clamp(0, target);
  bool isUnlocked(PlayerProfile p) => metric(p) >= target;
}

int _best(PlayerProfile p, String mode) => p.bestScores[mode] ?? 0;
int _bestAny(PlayerProfile p) =>
    p.bestScores.values.fold(0, (m, v) => v > m ? v : m);

final List<Achievement> achievements = [
  Achievement(
    id: 'first_merge',
    title: 'Первое слияние',
    description: 'Объедини три одинаковых числа',
    reward: 20,
    target: 1,
    metric: (p) => p.stats.totalMerges,
  ),
  Achievement(
    id: 'merges_100',
    title: 'Сотня',
    description: 'Сделай 100 слияний',
    reward: 50,
    target: 100,
    metric: (p) => p.stats.totalMerges,
  ),
  Achievement(
    id: 'merges_1000',
    title: 'Мастер потока',
    description: 'Сделай 1000 слияний',
    reward: 200,
    target: 1000,
    metric: (p) => p.stats.totalMerges,
  ),
  Achievement(
    id: 'tile_64',
    title: 'Шестьдесят четыре',
    description: 'Получи блок 64',
    reward: 30,
    target: 64,
    metric: (p) => p.stats.maxTile,
  ),
  Achievement(
    id: 'tile_256',
    title: 'Высокое давление',
    description: 'Получи блок 256',
    reward: 80,
    target: 256,
    metric: (p) => p.stats.maxTile,
  ),
  Achievement(
    id: 'tile_1024',
    title: 'Тысячник',
    description: 'Получи блок 1024',
    reward: 300,
    target: 1024,
    metric: (p) => p.stats.maxTile,
  ),
  Achievement(
    id: 'score_2000',
    title: 'Разгон',
    description: 'Набери 2000 очков за партию',
    reward: 40,
    target: 2000,
    metric: _bestAny,
  ),
  Achievement(
    id: 'score_10000',
    title: 'Полноводье',
    description: 'Набери 10 000 очков за партию',
    reward: 150,
    target: 10000,
    metric: _bestAny,
  ),
  Achievement(
    id: 'chain_3',
    title: 'Цепная реакция',
    description: 'Сделай цепочку из 3 слияний',
    reward: 60,
    target: 3,
    metric: (p) => p.stats.bestChain,
  ),
  Achievement(
    id: 'combo_5',
    title: 'В ритме',
    description: 'Достигни комбо ×5',
    reward: 60,
    target: 5,
    metric: (p) => p.stats.bestCombo,
  ),
  Achievement(
    id: 'stones_25',
    title: 'Камнелом',
    description: 'Разбей 25 камней',
    reward: 50,
    target: 25,
    metric: (p) => p.stats.stonesDestroyed,
  ),
  Achievement(
    id: 'games_10',
    title: 'Втянулся',
    description: 'Сыграй 10 партий',
    reward: 40,
    target: 10,
    metric: (p) => p.stats.gamesPlayed,
  ),
  Achievement(
    id: 'games_50',
    title: 'Завсегдатай',
    description: 'Сыграй 50 партий',
    reward: 120,
    target: 50,
    metric: (p) => p.stats.gamesPlayed,
  ),
  Achievement(
    id: 'daily_1',
    title: 'Испытатель',
    description: 'Выполни цель Daily Challenge',
    reward: 50,
    target: 1,
    metric: (p) => p.stats.dailyCompleted,
  ),
  Achievement(
    id: 'time_attack_3000',
    title: 'На время',
    description: 'Набери 3000 очков в Time Attack',
    reward: 80,
    target: 3000,
    metric: (p) => _best(p, 'time_attack'),
  ),
];
