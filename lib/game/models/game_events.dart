import 'bonus_type.dart';
import 'position.dart';
import 'tile.dart';

/// Things that happened inside the engine. The UI turns them into effects
/// (sounds, particles, popups); the engine itself never depends on the UI.
sealed class GameEvent {
  const GameEvent();
}

class TileSpawned extends GameEvent {
  const TileSpawned(this.tile, this.at);
  final Tile tile;
  final Pos at;
}

class TilesFlowed extends GameEvent {
  const TilesFlowed(this.count);
  final int count;
}

class TilesSwapped extends GameEvent {
  const TilesSwapped(this.a, this.b);
  final Pos a;
  final Pos b;
}

class MergeHappened extends GameEvent {
  const MergeHappened({
    required this.anchor,
    required this.consumed,
    required this.resultTile,
    required this.groupSize,
    required this.points,
    required this.chain,
    required this.combo,
    required this.doubled,
  });

  final Pos anchor;

  /// Tiles that disappeared into the anchor, with their last positions.
  final List<(Tile, Pos)> consumed;
  final Tile resultTile;
  final int groupSize;
  final int points;
  final int chain;
  final int combo;
  final bool doubled;
}

class StoneDestroyed extends GameEvent {
  const StoneDestroyed(this.tile, this.at, this.points);
  final Tile tile;
  final Pos at;
  final int points;
}

class TileRemoved extends GameEvent {
  const TileRemoved(this.tile, this.at);
  final Tile tile;
  final Pos at;
}

class LevelUp extends GameEvent {
  const LevelUp(this.level);
  final int level;
}

class ComboReset extends GameEvent {
  const ComboReset();
}

class BonusApplied extends GameEvent {
  const BonusApplied(this.type);
  final BonusType type;
}

enum GameOverReason { overflow, timeUp }

class GameOver extends GameEvent {
  const GameOver(this.reason);
  final GameOverReason reason;
}
