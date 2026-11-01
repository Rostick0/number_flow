enum TileKind { number, stone }

/// An immutable block on the board.
///
/// [id] is stable for the lifetime of a block so the UI can animate it
/// between cells. A merge keeps the anchor tile's id and changes its value.
class Tile {
  const Tile({
    required this.id,
    required this.value,
    this.kind = TileKind.number,
    this.frozenTicks = 0,
  });

  final int id;
  final int value;
  final TileKind kind;

  /// Ticks left under ice. A frozen tile cannot be moved by the player.
  final int frozenTicks;

  bool get isStone => kind == TileKind.stone;
  bool get isFrozen => frozenTicks > 0;
  bool get isMovable => !isStone && !isFrozen;
  bool get canMerge => !isStone;

  Tile copyWith({int? value, int? frozenTicks}) => Tile(
        id: id,
        value: value ?? this.value,
        kind: kind,
        frozenTicks: frozenTicks ?? this.frozenTicks,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'v': value,
        'k': kind.index,
        'f': frozenTicks,
      };

  static Tile fromJson(Map<String, dynamic> json) => Tile(
        id: json['id'] as int,
        value: json['v'] as int,
        kind: TileKind.values[json['k'] as int],
        frozenTicks: json['f'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is Tile &&
      other.id == id &&
      other.value == value &&
      other.kind == kind &&
      other.frozenTicks == frozenTicks;

  @override
  int get hashCode => Object.hash(id, value, kind, frozenTicks);

  @override
  String toString() => isStone ? 'Stone#$id' : 'Tile#$id($value)';
}
