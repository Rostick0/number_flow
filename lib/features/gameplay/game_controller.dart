import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../game/engine/game_engine.dart';
import '../../game/models/bonus_type.dart';
import '../../game/models/game_events.dart';
import '../../game/models/position.dart';
import '../../game/modes/game_mode.dart';
import '../../game/modes/mode_registry.dart';
import '../../services/ads/ad_service.dart';
import '../../services/audio/audio_service.dart';
import '../../services/audio/feedback_service.dart';
import '../profile/game_result.dart';
import '../profile/profile_controller.dart';
import 'game_view_state.dart';
import 'saved_game.dart';

@immutable
class GameLaunch {
  const GameLaunch(this.modeId, {this.resume = false});

  final String modeId;
  final bool resume;

  @override
  bool operator ==(Object other) =>
      other is GameLaunch && other.modeId == modeId && other.resume == resume;

  @override
  int get hashCode => Object.hash(modeId, resume);
}

enum BonusRequest { applied, targeting, cancelled, needsStock, unavailable }

/// Connects the pure [GameEngine] with time, the profile and the UI.
class GameController extends AutoDisposeFamilyNotifier<GameViewState, GameLaunch> {
  static const frame = Duration(milliseconds: 33);
  static const maxFrameStep = Duration(milliseconds: 250);
  static const autosaveEveryTicks = 10;

  late GameMode _mode;
  late int _seed;
  late GameEngine _engine;
  late SavedGameRepository _repo;
  final _events = StreamController<List<GameEvent>>.broadcast();
  Timer? _loop;
  late DateTime _lastFrame;
  bool _paused = false;
  bool _disposed = false;
  int? _selectedId;
  bool _removeMode = false;
  RewardSummary? _summary;
  int _lastSavedTick = 0;
  int _generation = 0;

  /// Effects stream for the UI (particles, popups).
  Stream<List<GameEvent>> get events => _events.stream;

  /// Read every frame by the flow indicator without rebuilding widgets.
  double get tickProgress => _engine.tickProgress;
  bool get isRunning => !_paused && !_engine.isOver;

  @override
  GameViewState build(GameLaunch launch) {
    _mode = ModeRegistry.byId(launch.modeId);
    _repo = ref.read(savedGameRepositoryProvider);
    final saved = launch.resume ? _repo.load() : null;
    if (saved != null && saved.modeId == _mode.id) {
      _seed = saved.seed;
      _engine = saved.restore();
    } else {
      _createEngine();
    }
    _lastSavedTick = _engine.tickCount;

    ref.listen(profileProvider.select((p) => p.bonuses), (_, _) => _emit());
    ref.onDispose(() {
      _disposed = true;
      _loop?.cancel();
      _persist();
      _events.close();
    });
    _startLoop();
    return _compose();
  }

  void _createEngine() {
    final now = ref.read(clockProvider)();
    _seed = _mode.newSeed(now, math.Random());
    _engine = GameEngine(_mode.config(_seed));
  }

  // ------------------------------------------------------------------ loop

  void _startLoop() {
    _lastFrame = ref.read(clockProvider)();
    _loop = Timer.periodic(frame, (_) => _onFrame());
  }

  void _onFrame() {
    // Real elapsed time (not timer count) keeps the pace exact under jank.
    final now = ref.read(clockProvider)();
    var dt = now.difference(_lastFrame);
    _lastFrame = now;
    if (!isRunning) return;
    if (dt > maxFrameStep) dt = maxFrameStep;
    final events = _engine.update(dt);
    if (events.isNotEmpty) {
      _handle(events);
    } else if (_secondsChanged()) {
      _emit();
    }
  }

  bool _secondsChanged() =>
      _timeSeconds() != state.timeSecondsLeft ||
      _engine.slowMotionLeft.inSeconds != state.slowSecondsLeft;

  int? _timeSeconds() {
    final left = _engine.timeLeft;
    return left == null ? null : (left.inMilliseconds / 1000).ceil();
  }

  void _handle(List<GameEvent> events) {
    ref.read(feedbackProvider).onEvents(events);
    if (!_events.isClosed) _events.add(events);
    if (events.any((e) => e is GameOver)) {
      _finishGame();
    } else if (_engine.tickCount - _lastSavedTick >= autosaveEveryTicks) {
      _persist();
    }
    _emit();
  }

  void _finishGame() {
    _repo.clear();
    _removeMode = false;
    _selectedId = null;
    _summary = ref.read(profileProvider.notifier).recordGame(GameResult(
          modeId: _mode.id,
          score: _engine.score,
          stats: _engine.stats,
          duration: _engine.elapsed,
        ));
    ref.read(adServiceProvider).onGameFinished();
  }

  void _persist() {
    if (_engine.isOver) return;
    _repo.save(_mode.id, _seed, _engine);
    _lastSavedTick = _engine.tickCount;
  }

  // --------------------------------------------------------------- actions

  void swipe(Pos from, Direction direction) {
    if (!isRunning || _removeMode) return;
    _selectedId = null;
    final events = _engine.swap(from, direction);
    if (events == null) return _rejectMove();
    _handle(events);
  }

  void tapCell(Pos p) {
    if (!isRunning) return;
    if (_removeMode) return _removeAt(p);
    final selected = _selectedPos();
    if (selected == p) {
      _selectedId = null;
      return _emit();
    }
    if (selected != null && selected.isAdjacentTo(p)) {
      _selectedId = null;
      final events = _engine.swapCells(selected, p);
      if (events == null) return _rejectMove();
      return _handle(events);
    }
    final tile = _engine.tileAt(p);
    _selectedId = tile != null && tile.isMovable ? tile.id : null;
    _emit();
  }

  void _rejectMove() {
    final feedback = ref.read(feedbackProvider);
    feedback.play(Sfx.invalid);
    feedback.haptic(HapticStrength.light);
    _emit();
  }

  BonusRequest requestBonus(BonusType type) {
    if (!isRunning) return BonusRequest.unavailable;
    if (type == BonusType.remove && _removeMode) {
      _removeMode = false;
      _emit();
      return BonusRequest.cancelled;
    }
    if (!_engine.canUseBonus(type)) return BonusRequest.unavailable;
    final profile = ref.read(profileProvider.notifier);
    if (ref.read(profileProvider).bonusCount(type) <= 0) return BonusRequest.needsStock;
    if (type == BonusType.remove) {
      _removeMode = true;
      _selectedId = null;
      _emit();
      return BonusRequest.targeting;
    }
    final events = switch (type) {
      BonusType.undo => _engine.useUndo(),
      BonusType.shuffle => _engine.useShuffle(),
      BonusType.doubleMerge => _engine.useDoubleMerge(),
      BonusType.slowMotion => _engine.useSlowMotion(),
      BonusType.remove => null,
    };
    if (events == null) return BonusRequest.unavailable;
    profile.consumeBonus(type);
    _selectedId = null;
    ref.read(feedbackProvider).play(Sfx.reward);
    _handle(events);
    return BonusRequest.applied;
  }

  void _removeAt(Pos p) {
    final events = _engine.useRemove(p);
    if (events == null) return;
    ref.read(profileProvider.notifier).consumeBonus(BonusType.remove);
    _removeMode = false;
    ref.read(feedbackProvider).haptic(HapticStrength.medium);
    _handle(events);
  }

  void pause() {
    if (_paused || _engine.isOver) return;
    _paused = true;
    _removeMode = false;
    _persist();
    _emit();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _emit();
  }

  /// Saves the unfinished game (called when the app goes to background).
  void saveNow() => _persist();

  void restart() {
    _repo.clear();
    _createEngine();
    _lastSavedTick = 0;
    _paused = false;
    _removeMode = false;
    _selectedId = null;
    _summary = null;
    _generation++;
    if (!_events.isClosed) _events.add(const []);
    _emit();
  }

  /// Rewarded ad that credits the game reward once more.
  Future<bool> doubleReward() async {
    final summary = _summary;
    if (summary == null || summary.doubled || summary.coins == 0) return false;
    final earned = await ref.read(adServiceProvider).showRewarded();
    if (!earned || _disposed) return false;
    ref.read(profileProvider.notifier).addCoins(summary.coins);
    ref.read(feedbackProvider).play(Sfx.reward);
    _summary = summary.markDoubled();
    _emit();
    return true;
  }

  // ----------------------------------------------------------------- state

  Pos? _selectedPos() {
    final id = _selectedId;
    if (id == null) return null;
    final cells = _engine.cells;
    final index = cells.indexWhere((t) => t?.id == id);
    if (index < 0 || !cells[index]!.isMovable) return null;
    return Pos(index ~/ _engine.size, index % _engine.size);
  }

  void _emit() {
    if (_disposed) return;
    state = _compose();
  }

  GameViewState _compose() {
    final profile = ref.read(profileProvider);
    return GameViewState(
      modeId: _mode.id,
      cells: _engine.cells,
      size: _engine.size,
      score: _engine.score,
      best: math.max(profile.bestFor(_mode.id), _engine.score),
      level: _engine.level,
      next: _engine.next,
      fillRatio: _engine.fillRatio,
      freeEntryCells: _engine.freeEntryCells,
      combo: _engine.combo,
      comboMultiplier: _engine.comboMultiplier,
      doubleArmed: _engine.doubleArmed,
      slowSecondsLeft: _engine.slowMotionLeft.inSeconds,
      timeSecondsLeft: _timeSeconds(),
      targetScore: _mode.targetScore(ref.read(clockProvider)()),
      paused: _paused,
      selected: _selectedPos(),
      removeMode: _removeMode,
      bonuses: {
        for (final t in BonusType.values)
          t: BonusSlot(
            stock: profile.bonusCount(t),
            usesLeft: _engine.bonusUsesLeft(t),
            usable: _engine.canUseBonus(t),
          ),
      },
      stats: _engine.stats,
      summary: _summary,
      isOver: _engine.isOver,
      overReason: _engine.overReason,
      generation: _generation,
    );
  }
}

final gameControllerProvider = NotifierProvider.autoDispose
    .family<GameController, GameViewState, GameLaunch>(GameController.new);
