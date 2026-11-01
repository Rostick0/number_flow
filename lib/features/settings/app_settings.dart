class AppSettings {
  const AppSettings({
    this.sound = true,
    this.vibration = true,
    this.tutorialSeen = false,
  });

  final bool sound;
  final bool vibration;
  final bool tutorialSeen;

  AppSettings copyWith({bool? sound, bool? vibration, bool? tutorialSeen}) =>
      AppSettings(
        sound: sound ?? this.sound,
        vibration: vibration ?? this.vibration,
        tutorialSeen: tutorialSeen ?? this.tutorialSeen,
      );

  Map<String, dynamic> toJson() =>
      {'sound': sound, 'vibration': vibration, 'tutorial': tutorialSeen};

  static AppSettings fromJson(Map<String, dynamic>? j) => j == null
      ? const AppSettings()
      : AppSettings(
          sound: j['sound'] as bool? ?? true,
          vibration: j['vibration'] as bool? ?? true,
          tutorialSeen: j['tutorial'] as bool? ?? false,
        );
}
