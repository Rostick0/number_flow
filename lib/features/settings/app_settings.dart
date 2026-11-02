class AppSettings {
  const AppSettings({
    this.sound = true,
    this.music = true,
    this.vibration = true,
    this.tutorialSeen = false,
  });

  final bool sound;
  final bool music;
  final bool vibration;
  final bool tutorialSeen;

  AppSettings copyWith({bool? sound, bool? music, bool? vibration, bool? tutorialSeen}) =>
      AppSettings(
        sound: sound ?? this.sound,
        music: music ?? this.music,
        vibration: vibration ?? this.vibration,
        tutorialSeen: tutorialSeen ?? this.tutorialSeen,
      );

  Map<String, dynamic> toJson() =>
      {'sound': sound, 'music': music, 'vibration': vibration, 'tutorial': tutorialSeen};

  static AppSettings fromJson(Map<String, dynamic>? j) => j == null
      ? const AppSettings()
      : AppSettings(
          sound: j['sound'] as bool? ?? true,
          music: j['music'] as bool? ?? true,
          vibration: j['vibration'] as bool? ?? true,
          tutorialSeen: j['tutorial'] as bool? ?? false,
        );
}
