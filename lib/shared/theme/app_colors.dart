import 'package:flutter/material.dart';

/// Colors of one visual theme, including the tile palette.
///
/// Read it with `context.colors`: widgets that do rebuild and cross-fade when
/// the player switches themes. Painters take the colors as fields so their
/// `shouldRepaint` notices the change.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.board,
    required this.cell,
    required this.ink,
    required this.inkSoft,
    required this.accent,
    this.coin = const Color(0xFFF2B33D),
    this.coinEdge = const Color(0xFFD99A22),
    required this.danger,
    required this.success,
    this.ice = const Color(0xFFBFE6FF),
    required this.stone,
    required this.stoneDark,
    required this.tiles,
    required this.tileBeyond,
    required this.tileInkDark,
    this.darkTextOn = const {2},
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color board;
  final Color cell;
  final Color ink;
  final Color inkSoft;
  final Color accent;
  final Color coin;
  final Color coinEdge;
  final Color danger;
  final Color success;
  final Color ice;
  final Color stone;
  final Color stoneDark;

  /// Tile colors from 2 upwards, one per doubling.
  final List<Color> tiles;

  /// Color of tiles past the end of [tiles]; their number is drawn in [coin].
  final Color tileBeyond;

  /// Text color for tiles too light for white text.
  final Color tileInkDark;

  /// Tile values drawn with [tileInkDark] instead of white.
  final Set<int> darkTextOn;

  static int _index(int value) {
    var i = 0;
    var v = value;
    while (v > 2) {
      v >>= 1;
      i++;
    }
    return i;
  }

  Color tileColor(int value) {
    final i = _index(value);
    return i < tiles.length ? tiles[i] : tileBeyond;
  }

  Color tileText(int value) {
    if (darkTextOn.contains(value)) return tileInkDark;
    if (_index(value) >= tiles.length) return coin;
    return Colors.white;
  }

  /// Darker shade used for the tile's bottom edge.
  static Color edgeFor(Color c) => Color.lerp(c, Colors.black, 0.18)!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    final near = t < 0.5 ? this : other;
    return AppColors(
      brightness: near.brightness,
      background: l(background, other.background),
      surface: l(surface, other.surface),
      board: l(board, other.board),
      cell: l(cell, other.cell),
      ink: l(ink, other.ink),
      inkSoft: l(inkSoft, other.inkSoft),
      accent: l(accent, other.accent),
      coin: l(coin, other.coin),
      coinEdge: l(coinEdge, other.coinEdge),
      danger: l(danger, other.danger),
      success: l(success, other.success),
      ice: l(ice, other.ice),
      stone: l(stone, other.stone),
      stoneDark: l(stoneDark, other.stoneDark),
      tiles: [
        for (var i = 0; i < tiles.length && i < other.tiles.length; i++) l(tiles[i], other.tiles[i]),
      ],
      tileBeyond: l(tileBeyond, other.tileBeyond),
      tileInkDark: l(tileInkDark, other.tileInkDark),
      darkTextOn: near.darkTextOn,
    );
  }
}

extension AppColorsOf on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
