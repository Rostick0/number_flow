import '../../shared/theme/game_themes.dart';

class AppSettings {
  const AppSettings({
    this.sound = true,
    this.music = true,
    this.vibration = true,
    this.tutorialSeen = false,
    this.theme = GameTheme.classic,
  });

  final bool sound;
  final bool music;
  final bool vibration;
  final bool tutorialSeen;
  final GameTheme theme;

  AppSettings copyWith({
    bool? sound,
    bool? music,
    bool? vibration,
    bool? tutorialSeen,
    GameTheme? theme,
  }) =>
      AppSettings(
        sound: sound ?? this.sound,
        music: music ?? this.music,
        vibration: vibration ?? this.vibration,
        tutorialSeen: tutorialSeen ?? this.tutorialSeen,
        theme: theme ?? this.theme,
      );

  Map<String, dynamic> toJson() => {
        'sound': sound,
        'music': music,
        'vibration': vibration,
        'tutorial': tutorialSeen,
        'theme': theme.name,
      };

  static AppSettings fromJson(Map<String, dynamic>? j) => j == null
      ? const AppSettings()
      : AppSettings(
          sound: j['sound'] as bool? ?? true,
          music: j['music'] as bool? ?? true,
          vibration: j['vibration'] as bool? ?? true,
          tutorialSeen: j['tutorial'] as bool? ?? false,
          theme: GameTheme.byName(j['theme'] as String?),
        );
}
