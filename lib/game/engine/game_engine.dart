import 'dart:math' as math;

import '../mechanics/difficulty.dart';
import '../mechanics/flow_rule.dart';
import '../mechanics/merge_rule.dart';
import '../mechanics/scoring.dart';
import '../mechanics/seeded_random.dart';
import '../mechanics/spawn_rule.dart';
import '../models/board.dart';
import '../models/bonus_type.dart';
import '../models/game_events.dart';
import '../models/position.dart';
import '../models/session_stats.dart';
import '../models/tile.dart';
import 'engine_config.dart';
import 'engine_snapshot.dart';

enum GameStatus { running, over }

/// Pure-Dart game simulation. Time is injected through [update], so the
/// engine is fully deterministic and testable without Flutter.
///
/// Every public mutating method returns the list of [GameEvent]s it produced.
/// Invariant: after any public call the board has no mergeable group.
class GameEngine {
  GameEngine(
    this.config, {
    this.flowRule = const GravityFlowRule(),
    this.mergeRule = const MergeRule(),
    this.difficulty = const DifficultyCurve(),
    this.scoring = const ScoreCalculator(),
    SpawnRule? spawnRule,
  })  : spawnRule = spawnRule ?? SpawnRule(difficulty: difficulty),
        _board = Board(config.size),
        _rng = SeededRandom(config.seed),
        _auxRng = SeededRandom(config.seed ^ 0x5bd1e995),
        _level = config.startLevel,
        _timeLeft = config.timeLimit {
    this.spawnRule.fillInitial(
          _board,
          config.initialTiles,
          _rng,
          () => _nextId++,
          mergeRule,
        );
    _next = this.spawnRule.next(_level, _rng, _board.maxValue);
    _stats = SessionStats(maxValue: _board.maxValue);
  }

  /// Rebuilds an engine from a saved game.
  factory GameEngine.restore(
    EngineConfig config,
    EngineSnapshot snapshot, {
    FlowRule flowRule = const GravityFlowRule(),
    MergeRule mergeRule = const MergeRule(),
    DifficultyCurve difficulty = const DifficultyCurve(),
    ScoreCalculator scoring = const ScoreCalculator(),
  }) {
    final engine = GameEngine(
      config,
      flowRule: flowRule,
      mergeRule: mergeRule,
      difficulty: difficulty,
      scoring: scoring,
    );
    engine._applyCore(snapshot.core);
    engine._elapsed = snapshot.elapsed;
    engine._timeLeft = snapshot.timeLeft;
    engine._tickAccumulator = snapshot.tickAccumulator;
    engine._slowMotionLeft = snapshot.slowMotionLeft;
    engine._bonusUses.addAll(snapshot.bonusUses);
    return engine;
  }

  /// Starts from an explicit board layout (tests, tutorials, custom modes).
  /// [cells] is row-major and must contain no mergeable group.
  factory GameEngine.fromCells(
    EngineConfig config,
    List<Tile?> cells, {
    SpawnSpec? next,
  }) {
    final engine = GameEngine(config);
    final board = Board(config.size);
    for (final p in board.positions) {
      board[p] = cells[p.row * config.size + p.col];
    }
    assert(engine.mergeRule.findGroups(board).isEmpty);
    engine._board = board;
    engine._nextId = cells.fold<int>(0, (m, t) => math.max(m, t?.id ?? 0)) + 1;
    engine._next = next ?? engine.spawnRule.next(engine._level, engine._rng, board.maxValue);
    engine._stats = SessionStats(maxValue: board.maxValue);
    return engine;
  }

  final EngineConfig config;
  final FlowRule flowRule;
  final MergeRule mergeRule;
  final SpawnRule spawnRule;
  final DifficultyCurve difficulty;
  final ScoreCalculator scoring;

  Board _board;
  final SeededRandom _rng;
  final SeededRandom _auxRng;
  int _nextId = 1;
  late SpawnSpec _next;
  int _score = 0;
  int _level;
  int _combo = 0;
  int? _lastMergeTick;
  int _tick = 0;
  late SessionStats _stats;
  bool _doubleArmed = false;

  Duration _elapsed = Duration.zero;
  Duration? _timeLeft;
  Duration _tickAccumulator = Duration.zero;
  Duration _slowMotionLeft = Duration.zero;
  final Map<BonusType, int> _bonusUses = {for (final t in BonusType.values) t: 0};
  CoreState? _undo;

  GameStatus _status = GameStatus.running;
  GameOverReason? _overReason;

  // ---------------------------------------------------------------- getters

  List<Tile?> get cells => _board.cells;
  Tile? tileAt(Pos p) => _board[p];
  int get size => _board.size;
  int get score => _score;
  int get level => _level;
  int get combo => _combo;
  double get comboMultiplier => scoring.comboMultiplier(_combo);
  SpawnSpec get next => _next;
  int get tickCount => _tick;
  bool get doubleArmed => _doubleArmed;
  Duration get elapsed => _elapsed;
  Duration? get timeLeft => _timeLeft;
  Duration get slowMotionLeft => _slowMotionLeft;
  bool get isSlowMotion => _slowMotionLeft > Duration.zero;
  GameStatus get status => _status;
  bool get isOver => _status == GameStatus.over;
  GameOverReason? get overReason => _overReason;
  double get fillRatio => _board.fillRatio;
  int get freeEntryCells =>
      flowRule.entryCells(_board).where((p) => _board[p] == null).length;
  bool get canUndo => _undo != null;

  SessionStats get stats => _stats.copyWith(
        bonusesUsed: _bonusUses.values.fold<int>(0, (a, b) => a + b),
      );

  Duration get tickInterval {
    final base = difficulty.tickInterval(_level);
    return isSlowMotion ? base * config.slowMotionFactor : base;
  }

  /// 0..1 progress towards the next tick, for the flow indicator.
  double get tickProgress => math.min(
        1,
        _tickAccumulator.inMicroseconds / tickInterval.inMicroseconds,
      );

  int bonusUsesLeft(BonusType type) =>
      config.bonusUsesPerGame - (_bonusUses[type] ?? 0);

  // ------------------------------------------------------------------ time

  /// Advances game time; runs as many ticks as fit into the elapsed time.
  List<GameEvent> update(Duration dt) {
    if (isOver || dt <= Duration.zero) return const [];
    final events = <GameEvent>[];
    _elapsed += dt;
    if (_slowMotionLeft > Duration.zero) {
      _slowMotionLeft -= dt;
      if (_slowMotionLeft < Duration.zero) _slowMotionLeft = Duration.zero;
    }
    final timeLeft = _timeLeft;
    if (timeLeft != null) {
      _timeLeft = timeLeft - dt;
      if (_timeLeft! <= Duration.zero) {
        _timeLeft = Duration.zero;
        _finish(GameOverReason.timeUp, events);
        return events;
      }
    }
    _tickAccumulator += dt;
    while (!isOver && _tickAccumulator >= tickInterval) {
      _tickAccumulator -= tickInterval;
      events.addAll(tick());
    }
    return events;
  }

  /// One flow step: flow, thaw, merge, spawn. See GAME_DESIGN.md §3.
  List<GameEvent> tick() {
    if (isOver) return const [];
    final events = <GameEvent>[];
    _tick++;
    _stats = _stats.copyWith(ticks: _stats.ticks + 1);

    final moved = flowRule.step(_board);
    if (moved.isNotEmpty) events.add(TilesFlowed(moved.length));
    _thaw();
    final mergedAfterFlow = _resolve(moved.toSet(), events);

    if (!mergedAfterFlow &&
        _combo > 0 &&
        _tick - (_lastMergeTick ?? 0) > scoring.comboWindowTicks) {
      _combo = 0;
      events.add(const ComboReset());
    }

    final cell = spawnRule.pickCell(flowRule.entryCells(_board), _board, _rng);
    if (cell == null) {
      _finish(GameOverReason.overflow, events);
      return events;
    }
    final tile = spawnRule.build(_next, _nextId++);
    _board[cell] = tile;
    events.add(TileSpawned(tile, cell));
    _resolve({cell}, events);
    _next = spawnRule.next(_level, _rng, _board.maxValue);

    final undo = _undo;
    if (undo != null && _tick - undo.tick > config.undoMaxTicks) _undo = null;
    return events;
  }

  // --------------------------------------------------------------- player

  bool canSwap(Pos a, Pos b) {
    if (isOver || !a.isInside(size) || !b.isInside(size)) return false;
    if (!a.isAdjacentTo(b)) return false;
    final ta = _board[a];
    final tb = _board[b];
    if (ta == null && tb == null) return false;
    if (ta != null && !ta.isMovable) return false;
    if (tb != null && !tb.isMovable) return false;
    if (ta != null && tb != null && ta.value == tb.value) return false;
    return true;
  }

  /// Swaps the tile at [from] with its neighbour in [direction].
  /// Returns null when the move is not allowed.
  List<GameEvent>? swap(Pos from, Direction direction) =>
      swapCells(from, from + direction);

  List<GameEvent>? swapCells(Pos a, Pos b) {
    if (!canSwap(a, b)) return null;
    final before = _captureCore();
    final ta = _board[a];
    _board[a] = _board[b];
    _board[b] = ta;
    final events = <GameEvent>[TilesSwapped(a, b)];
    _resolve({a, b}, events);
    _undo = before;
    return events;
  }

  // --------------------------------------------------------------- bonuses

  bool canUseBonus(BonusType type) {
    if (isOver || bonusUsesLeft(type) <= 0) return false;
    return switch (type) {
      BonusType.undo => _undo != null,
      BonusType.remove => _board.occupiedCount > 0,
      BonusType.shuffle => _shufflable().map((p) => _board[p]!.value).toSet().length > 1,
      BonusType.doubleMerge => !_doubleArmed,
      BonusType.slowMotion => !isSlowMotion,
    };
  }

  List<GameEvent>? useUndo() {
    final undo = _undo;
    if (!canUseBonus(BonusType.undo) || undo == null) return null;
    _applyCore(undo);
    _undo = null;
    return _consumeBonus(BonusType.undo, []);
  }

  List<GameEvent>? useRemove(Pos at) {
    final tile = at.isInside(size) ? _board[at] : null;
    if (!canUseBonus(BonusType.remove) || tile == null) return null;
    _undo = _captureCore();
    _board[at] = null;
    return _consumeBonus(BonusType.remove, [TileRemoved(tile, at)]);
  }

  /// Permutes movable number tiles between their cells, then merges.
  List<GameEvent>? useShuffle() {
    if (!canUseBonus(BonusType.shuffle)) return null;
    _undo = _captureCore();
    final cellsToShuffle = _shufflable();
    final tiles = [for (final p in cellsToShuffle) _board[p]!];
    final original = [for (final t in tiles) t.value];
    for (var attempt = 0; attempt < 10; attempt++) {
      _auxRng.shuffle(tiles);
      final changed = [
        for (var i = 0; i < tiles.length; i++) tiles[i].value != original[i],
      ].any((c) => c);
      if (changed) break;
    }
    for (var i = 0; i < cellsToShuffle.length; i++) {
      _board[cellsToShuffle[i]] = tiles[i];
    }
    final events = _consumeBonus(BonusType.shuffle, []);
    _resolve(const {}, events);
    return events;
  }

  List<GameEvent>? useDoubleMerge() {
    if (!canUseBonus(BonusType.doubleMerge)) return null;
    _doubleArmed = true;
    return _consumeBonus(BonusType.doubleMerge, []);
  }

  List<GameEvent>? useSlowMotion() {
    if (!canUseBonus(BonusType.slowMotion)) return null;
    _slowMotionLeft = config.slowMotionDuration;
    return _consumeBonus(BonusType.slowMotion, []);
  }

  // ------------------------------------------------------------ snapshots

  EngineSnapshot snapshot() => EngineSnapshot(
        core: _captureCore(),
        elapsed: _elapsed,
        timeLeft: _timeLeft,
        tickAccumulator: _tickAccumulator,
        slowMotionLeft: _slowMotionLeft,
        bonusUses: Map.of(_bonusUses),
      );

  CoreState _captureCore() => CoreState(
        board: _board.copy(),
        rngState: _rng.state,
        auxRngState: _auxRng.state,
        nextId: _nextId,
        next: _next,
        score: _score,
        level: _level,
        combo: _combo,
        lastMergeTick: _lastMergeTick,
        tick: _tick,
        stats: _stats,
        doubleArmed: _doubleArmed,
      );

  void _applyCore(CoreState s) {
    _board = s.board.copy();
    _rng.state = s.rngState;
    _auxRng.state = s.auxRngState;
    _nextId = s.nextId;
    _next = s.next;
    _score = s.score;
    _level = s.level;
    _combo = s.combo;
    _lastMergeTick = s.lastMergeTick;
    _tick = s.tick;
    _stats = s.stats;
    _doubleArmed = s.doubleArmed;
  }

  // -------------------------------------------------------------- internals

  List<GameEvent> _consumeBonus(BonusType type, List<GameEvent> events) {
    _bonusUses[type] = (_bonusUses[type] ?? 0) + 1;
    events.insert(0, BonusApplied(type));
    return events;
  }

  List<Pos> _shufflable() => _board.occupied.where((p) {
        final t = _board[p]!;
        return t.isMovable;
      }).toList();

  void _thaw() {
    for (final p in _board.occupied.toList()) {
      final t = _board[p]!;
      if (t.isFrozen) _board[p] = t.copyWith(frozenTicks: t.frozenTicks - 1);
    }
  }

  /// Merges every group until the board is stable. Returns true if anything
  /// merged. [recent] are the cells changed by the triggering action.
  bool _resolve(Set<Pos> recent, List<GameEvent> events) {
    var anchors = recent;
    var chain = 0;
    while (true) {
      final groups = mergeRule.findGroups(_board);
      if (groups.isEmpty) break;
      if (chain == 0) _advanceCombo();
      chain++;
      final nextAnchors = <Pos>{};
      for (final group in groups) {
        nextAnchors.add(_mergeGroup(group, anchors, chain, events));
      }
      anchors = nextAnchors;
    }
    if (chain == 0) return false;
    _stats = _stats.copyWith(
      maxChain: math.max(_stats.maxChain, chain),
      maxCombo: math.max(_stats.maxCombo, _combo),
    );
    _updateLevel(events);
    return true;
  }

  void _advanceCombo() {
    final last = _lastMergeTick;
    final continues =
        _combo > 0 && last != null && _tick - last <= scoring.comboWindowTicks;
    _combo = continues ? _combo + 1 : 1;
    _lastMergeTick = _tick;
  }

  Pos _mergeGroup(List<Pos> group, Set<Pos> recent, int chain, List<GameEvent> events) {
    final anchor = mergeRule.pickAnchor(group, recent);
    final anchorTile = _board[anchor]!;
    final doubled = _doubleArmed;
    _doubleArmed = false;
    final value = mergeRule.resultValue(anchorTile.value, doubled: doubled);

    final consumed = <(Tile, Pos)>[];
    for (final p in group) {
      if (p == anchor) continue;
      consumed.add((_board[p]!, p));
      _board[p] = null;
    }
    final result = anchorTile.copyWith(value: value, frozenTicks: 0);
    _board[anchor] = result;

    final points = scoring.mergePoints(
      resultValue: value,
      groupSize: group.length,
      chain: chain,
      combo: _combo,
    );
    _score += points;
    _stats = _stats.copyWith(
      merges: _stats.merges + 1,
      mergedTiles: _stats.mergedTiles + group.length,
      maxValue: math.max(_stats.maxValue, value),
    );
    events.add(MergeHappened(
      anchor: anchor,
      consumed: consumed,
      resultTile: result,
      groupSize: group.length,
      points: points,
      chain: chain,
      combo: _combo,
      doubled: doubled,
    ));

    for (final p in group) {
      for (final n in p.neighbours(size)) {
        final stone = _board[n];
        if (stone == null || !stone.isStone) continue;
        _board[n] = null;
        final stonePoints = scoring.stonePoints(_level);
        _score += stonePoints;
        _stats = _stats.copyWith(stonesDestroyed: _stats.stonesDestroyed + 1);
        events.add(StoneDestroyed(stone, n, stonePoints));
      }
    }
    return anchor;
  }

  void _updateLevel(List<GameEvent> events) {
    final target = config.startLevel + _stats.merges ~/ config.mergesPerLevel;
    if (target > _level) {
      _level = target;
      events.add(LevelUp(_level));
    }
  }

  void _finish(GameOverReason reason, List<GameEvent> events) {
    _status = GameStatus.over;
    _overReason = reason;
    _undo = null;
    events.add(GameOver(reason));
  }
}
