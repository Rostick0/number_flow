/// Counters for one game session.
class SessionStats {
  const SessionStats({
    this.merges = 0,
    this.mergedTiles = 0,
    this.maxValue = 0,
    this.maxChain = 0,
    this.maxCombo = 0,
    this.stonesDestroyed = 0,
    this.bonusesUsed = 0,
    this.ticks = 0,
  });

  final int merges;
  final int mergedTiles;
  final int maxValue;
  final int maxChain;
  final int maxCombo;
  final int stonesDestroyed;
  final int bonusesUsed;
  final int ticks;

  SessionStats copyWith({
    int? merges,
    int? mergedTiles,
    int? maxValue,
    int? maxChain,
    int? maxCombo,
    int? stonesDestroyed,
    int? bonusesUsed,
    int? ticks,
  }) =>
      SessionStats(
        merges: merges ?? this.merges,
        mergedTiles: mergedTiles ?? this.mergedTiles,
        maxValue: maxValue ?? this.maxValue,
        maxChain: maxChain ?? this.maxChain,
        maxCombo: maxCombo ?? this.maxCombo,
        stonesDestroyed: stonesDestroyed ?? this.stonesDestroyed,
        bonusesUsed: bonusesUsed ?? this.bonusesUsed,
        ticks: ticks ?? this.ticks,
      );

  Map<String, dynamic> toJson() => {
        'merges': merges,
        'mergedTiles': mergedTiles,
        'maxValue': maxValue,
        'maxChain': maxChain,
        'maxCombo': maxCombo,
        'stones': stonesDestroyed,
        'bonuses': bonusesUsed,
        'ticks': ticks,
      };

  static SessionStats fromJson(Map<String, dynamic> json) => SessionStats(
        merges: json['merges'] as int? ?? 0,
        mergedTiles: json['mergedTiles'] as int? ?? 0,
        maxValue: json['maxValue'] as int? ?? 0,
        maxChain: json['maxChain'] as int? ?? 0,
        maxCombo: json['maxCombo'] as int? ?? 0,
        stonesDestroyed: json['stones'] as int? ?? 0,
        bonusesUsed: json['bonuses'] as int? ?? 0,
        ticks: json['ticks'] as int? ?? 0,
      );
}
