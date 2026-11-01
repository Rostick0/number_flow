import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/profile_controller.dart';
import '../../game/models/game_events.dart';
import 'audio_service.dart';

/// Turns game events into sound and haptics, respecting user settings.
class FeedbackService {
  FeedbackService(this._ref);

  final Ref _ref;

  bool get _sound => _ref.read(profileProvider).settings.sound;
  bool get _vibration => _ref.read(profileProvider).settings.vibration;

  void play(Sfx sfx) {
    if (_sound) _ref.read(audioServiceProvider).play(sfx);
  }

  void haptic(HapticStrength strength) {
    if (!_vibration) return;
    switch (strength) {
      case HapticStrength.light:
        HapticFeedback.lightImpact();
      case HapticStrength.medium:
        HapticFeedback.mediumImpact();
      case HapticStrength.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  void onEvents(List<GameEvent> events) {
    final merges = events.whereType<MergeHappened>().toList();
    if (merges.isNotEmpty) {
      final big = merges.any((m) => m.chain > 1 || m.combo >= 3 || m.doubled);
      play(big ? Sfx.combo : Sfx.merge);
      haptic(big ? HapticStrength.medium : HapticStrength.light);
    } else if (events.any((e) => e is TilesSwapped)) {
      play(Sfx.move);
    } else if (events.any((e) => e is TileSpawned)) {
      play(Sfx.spawn);
    }
    if (events.any((e) => e is LevelUp)) {
      play(Sfx.levelup);
      haptic(HapticStrength.medium);
    }
    if (events.any((e) => e is GameOver)) {
      play(Sfx.gameover);
      haptic(HapticStrength.heavy);
    }
  }
}

enum HapticStrength { light, medium, heavy }

final feedbackProvider = Provider<FeedbackService>(FeedbackService.new);
