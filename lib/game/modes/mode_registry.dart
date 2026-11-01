import 'game_mode.dart';

class ModeRegistry {
  static const List<GameMode> modes = [
    ClassicMode(),
    TimeAttackMode(),
    DailyChallengeMode(),
  ];

  static GameMode byId(String id) =>
      modes.firstWhere((m) => m.id == id, orElse: () => modes.first);
}
