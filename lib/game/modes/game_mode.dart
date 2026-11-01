import 'dart:math' as math;

import '../../core/day_key.dart';
import '../engine/engine_config.dart';

/// A way to play. Adding a mode = subclass + entry in [ModeRegistry].
abstract class GameMode {
  const GameMode();

  String get id;
  String get title;
  String get subtitle;

  /// Seed for a new game. Saved games keep their seed to rebuild the config.
  int newSeed(DateTime now, math.Random random) => random.nextInt(1 << 31);

  EngineConfig config(int seed);

  /// Daily-style modes can only resume a save made on the same day.
  bool canResume(int savedDayKey, DateTime now) => true;

  /// Score that grants the mode's goal reward, if the mode has a goal.
  int? targetScore(DateTime now) => null;
}

class ClassicMode extends GameMode {
  const ClassicMode();

  @override
  String get id => 'classic';
  @override
  String get title => 'Classic';
  @override
  String get subtitle => 'Держись, пока поле не переполнится';

  @override
  EngineConfig config(int seed) => EngineConfig(seed: seed);
}

class TimeAttackMode extends GameMode {
  const TimeAttackMode();

  static const duration = Duration(seconds: 120);

  @override
  String get id => 'time_attack';
  @override
  String get title => 'Time Attack';
  @override
  String get subtitle => '2 минуты — набери максимум очков';

  @override
  EngineConfig config(int seed) => EngineConfig(
        seed: seed,
        timeLimit: duration,
        startLevel: 2,
        mergesPerLevel: 6,
      );
}

/// Same seed, start layout and goal for every player on a given day.
class DailyChallengeMode extends GameMode {
  const DailyChallengeMode();

  @override
  String get id => 'daily';
  @override
  String get title => 'Daily';
  @override
  String get subtitle => 'Одинаковое испытание для всех на сегодня';

  @override
  int newSeed(DateTime now, math.Random random) => dayKeyOf(now);

  @override
  EngineConfig config(int seed) => EngineConfig(
        seed: seed,
        startLevel: 3,
        initialTiles: 8,
      );

  @override
  bool canResume(int savedDayKey, DateTime now) => savedDayKey == dayKeyOf(now);

  @override
  int targetScore(DateTime now) => 1500 + (dayKeyOf(now) % 5) * 250;
}
