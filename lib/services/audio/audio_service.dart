import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sound effects. Files are synthesized by `tool/gen_sfx.py` (own work).
enum Sfx { spawn, move, merge, combo, reward, gameover, invalid, levelup }

abstract class AudioService {
  Future<void> initialize();
  void play(Sfx sfx);
}

class SilentAudioService implements AudioService {
  const SilentAudioService();

  @override
  Future<void> initialize() async {}

  @override
  void play(Sfx sfx) {}
}

/// Low-latency pooled playback; a failing platform just stays silent.
class PooledAudioService implements AudioService {
  final Map<Sfx, AudioPool> _pools = {};

  static const _volumes = {
    Sfx.spawn: 0.25,
    Sfx.move: 0.4,
    Sfx.merge: 0.7,
    Sfx.combo: 0.8,
    Sfx.reward: 0.7,
    Sfx.gameover: 0.7,
    Sfx.invalid: 0.4,
    Sfx.levelup: 0.7,
  };

  @override
  Future<void> initialize() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build());
    } catch (e) {
      debugPrint('Audio context not set: $e');
    }
    for (final sfx in Sfx.values) {
      try {
        _pools[sfx] = await AudioPool.createFromAsset(
          path: 'sounds/${sfx.name}.wav',
          maxPlayers: sfx == Sfx.merge || sfx == Sfx.spawn ? 3 : 2,
          playerMode: PlayerMode.lowLatency,
        );
      } catch (e) {
        debugPrint('Sound ${sfx.name} unavailable: $e');
      }
    }
  }

  @override
  void play(Sfx sfx) {
    _pools[sfx]?.start(volume: _volumes[sfx]!).catchError((Object e) {
      debugPrint('Sound ${sfx.name} failed: $e');
      return () async {};
    });
  }
}

/// Overridden in `main()`.
final audioServiceProvider = Provider<AudioService>((ref) => const SilentAudioService());
