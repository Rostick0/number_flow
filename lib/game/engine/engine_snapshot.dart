import '../mechanics/spawn_rule.dart';
import '../models/board.dart';
import '../models/bonus_type.dart';
import '../models/session_stats.dart';

/// Board-related engine state. Used by Undo (restores this part only).
class CoreState {
  const CoreState({
    required this.board,
    required this.rngState,
    required this.auxRngState,
    required this.nextId,
    required this.next,
    required this.score,
    required this.level,
    required this.combo,
    required this.lastMergeTick,
    required this.tick,
    required this.stats,
    required this.doubleArmed,
  });

  final Board board;
  final int rngState;
  final int auxRngState;
  final int nextId;
  final SpawnSpec next;
  final int score;
  final int level;
  final int combo;
  final int? lastMergeTick;
  final int tick;
  final SessionStats stats;
  final bool doubleArmed;

  Map<String, dynamic> toJson() => {
        'board': board.toJson(),
        'rng': rngState,
        'aux': auxRngState,
        'nextId': nextId,
        'next': next.toJson(),
        'score': score,
        'level': level,
        'combo': combo,
        'lastMerge': lastMergeTick,
        'tick': tick,
        'stats': stats.toJson(),
        'double': doubleArmed,
      };

  static CoreState fromJson(int size, Map<String, dynamic> json) => CoreState(
        board: Board.fromJson(size, json['board'] as List<dynamic>),
        rngState: json['rng'] as int,
        auxRngState: json['aux'] as int,
        nextId: json['nextId'] as int,
        next: SpawnSpec.fromJson(json['next'] as Map<String, dynamic>),
        score: json['score'] as int,
        level: json['level'] as int,
        combo: json['combo'] as int,
        lastMergeTick: json['lastMerge'] as int?,
        tick: json['tick'] as int,
        stats: SessionStats.fromJson(json['stats'] as Map<String, dynamic>),
        doubleArmed: json['double'] as bool,
      );
}

/// Complete engine state for saving an unfinished game.
class EngineSnapshot {
  const EngineSnapshot({
    required this.core,
    required this.elapsed,
    required this.timeLeft,
    required this.tickAccumulator,
    required this.slowMotionLeft,
    required this.bonusUses,
  });

  final CoreState core;
  final Duration elapsed;
  final Duration? timeLeft;
  final Duration tickAccumulator;
  final Duration slowMotionLeft;
  final Map<BonusType, int> bonusUses;

  Map<String, dynamic> toJson() => {
        'core': core.toJson(),
        'elapsed': elapsed.inMilliseconds,
        'timeLeft': timeLeft?.inMilliseconds,
        'acc': tickAccumulator.inMilliseconds,
        'slow': slowMotionLeft.inMilliseconds,
        'bonusUses': {for (final e in bonusUses.entries) e.key.name: e.value},
      };

  static EngineSnapshot fromJson(int size, Map<String, dynamic> json) {
    final uses = json['bonusUses'] as Map<String, dynamic>;
    final timeLeft = json['timeLeft'] as int?;
    return EngineSnapshot(
      core: CoreState.fromJson(size, json['core'] as Map<String, dynamic>),
      elapsed: Duration(milliseconds: json['elapsed'] as int),
      timeLeft: timeLeft == null ? null : Duration(milliseconds: timeLeft),
      tickAccumulator: Duration(milliseconds: json['acc'] as int),
      slowMotionLeft: Duration(milliseconds: json['slow'] as int),
      bonusUses: {
        for (final t in BonusType.values) t: uses[t.name] as int? ?? 0,
      },
    );
  }
}
