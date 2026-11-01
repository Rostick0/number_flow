import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/day_key.dart';
import '../../game/engine/engine_snapshot.dart';
import '../../game/engine/game_engine.dart';
import '../../game/modes/game_mode.dart';
import '../../game/modes/mode_registry.dart';
import '../../services/storage/storage_service.dart';

/// An unfinished game that can be continued after leaving or an app restart.
class SavedGame {
  const SavedGame({
    required this.modeId,
    required this.seed,
    required this.dayKey,
    required this.snapshot,
  });

  final String modeId;
  final int seed;
  final int dayKey;
  final EngineSnapshot snapshot;

  GameMode get mode => ModeRegistry.byId(modeId);
  int get score => snapshot.core.score;

  GameEngine restore() => GameEngine.restore(mode.config(seed), snapshot);

  Map<String, dynamic> toJson() => {
        'mode': modeId,
        'seed': seed,
        'day': dayKey,
        'size': mode.config(seed).size,
        'snapshot': snapshot.toJson(),
      };

  static SavedGame? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    try {
      return SavedGame(
        modeId: j['mode'] as String,
        seed: j['seed'] as int,
        dayKey: j['day'] as int,
        snapshot: EngineSnapshot.fromJson(
          j['size'] as int,
          j['snapshot'] as Map<String, dynamic>,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

class SavedGameRepository {
  SavedGameRepository(this._storage, this._clock);

  final StorageService _storage;
  final Clock _clock;

  /// The saved game if it can still be resumed today.
  SavedGame? load() {
    final saved = SavedGame.fromJson(_storage.readJson(StorageService.savedGameKey));
    if (saved == null) return null;
    if (!saved.mode.canResume(saved.dayKey, _clock())) return null;
    return saved;
  }

  void save(String modeId, int seed, GameEngine engine) {
    if (engine.isOver) return clear();
    final saved = SavedGame(
      modeId: modeId,
      seed: seed,
      dayKey: dayKeyOf(_clock()),
      snapshot: engine.snapshot(),
    );
    _storage.writeJson(StorageService.savedGameKey, saved.toJson());
  }

  void clear() => _storage.remove(StorageService.savedGameKey);
}

final savedGameRepositoryProvider = Provider<SavedGameRepository>(
  (ref) => SavedGameRepository(ref.read(storageProvider), ref.read(clockProvider)),
);

/// Invalidate after leaving a game so the home screen sees the new save.
final savedGameProvider = Provider.autoDispose<SavedGame?>(
  (ref) => ref.watch(savedGameRepositoryProvider).load(),
);
