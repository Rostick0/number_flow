import '../../game/mechanics/spawn_rule.dart';
import '../../game/models/bonus_type.dart';
import '../../game/models/game_events.dart';
import '../../game/models/position.dart';
import '../../game/models/session_stats.dart';
import '../../game/models/tile.dart';
import '../profile/game_result.dart';

class BonusSlot {
  const BonusSlot({required this.stock, required this.usesLeft, required this.usable});

  /// Owned in the profile inventory.
  final int stock;

  /// Remaining uses allowed in this game.
  final int usesLeft;

  /// The engine accepts this bonus right now.
  final bool usable;

  @override
  bool operator ==(Object other) =>
      other is BonusSlot &&
      other.stock == stock &&
      other.usesLeft == usesLeft &&
      other.usable == usable;

  @override
  int get hashCode => Object.hash(stock, usesLeft, usable);
}

/// Immutable snapshot of a game for the UI.
class GameViewState {
  const GameViewState({
    required this.modeId,
    required this.cells,
    required this.size,
    required this.score,
    required this.best,
    required this.level,
    required this.next,
    required this.fillRatio,
    required this.freeEntryCells,
    required this.combo,
    required this.comboMultiplier,
    required this.doubleArmed,
    required this.slowSecondsLeft,
    required this.timeSecondsLeft,
    required this.targetScore,
    required this.paused,
    required this.selected,
    required this.removeMode,
    required this.bonuses,
    required this.stats,
    required this.summary,
    required this.isOver,
    required this.overReason,
    required this.generation,
  });

  final String modeId;
  final List<Tile?> cells;
  final int size;
  final int score;
  final int best;
  final int level;
  final SpawnSpec next;
  final double fillRatio;
  final int freeEntryCells;
  final int combo;
  final double comboMultiplier;
  final bool doubleArmed;
  final int slowSecondsLeft;
  final int? timeSecondsLeft;
  final int? targetScore;
  final bool paused;
  final Pos? selected;
  final bool removeMode;
  final Map<BonusType, BonusSlot> bonuses;
  final SessionStats stats;
  final RewardSummary? summary;
  final bool isOver;
  final GameOverReason? overReason;

  /// Changes on restart so tile widgets of the old game are not reused.
  final int generation;

  bool get inDanger => !isOver && freeEntryCells <= 1;
}
