import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calm background tracks. Files are synthesized by `tool/gen_music.py` (own work).
abstract class MusicService {
  Future<void> initialize();

  /// Follows the "music" setting.
  void setEnabled(bool enabled);

  /// Pauses while the app is in the background.
  void setForeground(bool foreground);

  /// Switches to another random track (a new round begins).
  void nextTrack();
}

class SilentMusicService implements MusicService {
  const SilentMusicService();

  @override
  Future<void> initialize() async {}

  @override
  void setEnabled(bool enabled) {}

  @override
  void setForeground(bool foreground) {}

  @override
  void nextTrack() {}
}

/// Plays the tracks one after another in random order, never repeating the
/// previous one; a failing platform just stays silent.
class PlayerMusicService implements MusicService {
  static const _tracks = ['drift', 'tide', 'glow', 'mist'];
  static const _volume = 0.35;

  final _random = Random();
  AudioPlayer? _player;
  String? _current;
  String? _last;
  bool _enabled = false;
  bool _foreground = true;

  @override
  Future<void> initialize() async {
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      player.onPlayerComplete.listen((_) {
        _current = null;
        _apply();
      });
      _player = player;
    } catch (e) {
      debugPrint('Music unavailable: $e');
    }
    _apply();
  }

  @override
  void setEnabled(bool enabled) {
    _enabled = enabled;
    _apply();
  }

  @override
  void setForeground(bool foreground) {
    _foreground = foreground;
    _apply();
  }

  @override
  void nextTrack() {
    if (!_enabled) return;
    _current = null;
    _apply();
  }

  void _apply() {
    final player = _player;
    if (player == null) return;
    if (!_enabled) {
      if (_current != null) {
        _current = null;
        _guard(player.stop());
      }
    } else if (!_foreground) {
      if (_current != null) _guard(player.pause());
    } else if (_current != null) {
      _guard(player.resume());
    } else {
      final options = _tracks.where((t) => t != _last).toList();
      _current = _last = options[_random.nextInt(options.length)];
      _guard(player.play(AssetSource('music/$_current.mp3'), volume: _volume));
    }
  }

  void _guard(Future<void> f) => f.catchError((Object e) => debugPrint('Music failed: $e'));
}

/// Overridden in `main()`.
final musicServiceProvider = Provider<MusicService>((ref) => const SilentMusicService());
