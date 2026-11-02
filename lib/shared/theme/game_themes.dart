import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Themes the player can buy and pick. The enum name is what gets saved, so
/// renaming a value resets that choice to [classic] and drops the purchase.
enum GameTheme {
  classic('Классика', _classic, 0),
  night('Ночь', _night, 200),
  ocean('Океан', _ocean, 300),
  forest('Лес', _forest, 300),
  sunset('Закат', _sunset, 400),
  neon('Неон', _neon, 500);

  const GameTheme(this.title, this.colors, this.price);

  final String title;
  final AppColors colors;

  /// Shop price in coins; free themes are owned from the start.
  final int price;
  bool get isFree => price == 0;

  static GameTheme byName(String? name) => values.asNameMap()[name] ?? classic;
}

/// Cool-to-warm progression: each doubling moves one step along the wheel.
const _classic = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFF4F1EA),
  surface: Color(0xFFFFFFFF),
  board: Color(0xFFE6E0D4),
  cell: Color(0xFFEFEAE1),
  ink: Color(0xFF2B2D42),
  inkSoft: Color(0xFF6B6E80),
  accent: Color(0xFF5B6CFF),
  danger: Color(0xFFE5534B),
  success: Color(0xFF3DBE8B),
  stone: Color(0xFF9AA0A6),
  stoneDark: Color(0xFF7D838A),
  tiles: [
    Color(0xFF7FD1C7), // 2
    Color(0xFF5DB8E8), // 4
    Color(0xFF5B8DEF), // 8
    Color(0xFF6C6CE5), // 16
    Color(0xFF8F5BD9), // 32
    Color(0xFFC254C4), // 64
    Color(0xFFE2558F), // 128
    Color(0xFFF06B5E), // 256
    Color(0xFFF58A3D), // 512
    Color(0xFFF2B33D), // 1024
    Color(0xFFD9B530), // 2048
  ],
  tileBeyond: Color(0xFF2B2D42),
  tileInkDark: Color(0xFF1F4D48),
);

/// The classic tiles on a dark indigo board.
const _night = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF14161F),
  surface: Color(0xFF1F2231),
  board: Color(0xFF282C3E),
  cell: Color(0xFF32374C),
  ink: Color(0xFFE8EAF2),
  inkSoft: Color(0xFF9296AB),
  accent: Color(0xFF7B88FF),
  coinEdge: Color(0xFFC98A1B),
  danger: Color(0xFFFF6B63),
  success: Color(0xFF4FD19C),
  ice: Color(0xFF9CD8FF),
  stone: Color(0xFF6E7480),
  stoneDark: Color(0xFF535862),
  tiles: [
    Color(0xFF7FD1C7),
    Color(0xFF5DB8E8),
    Color(0xFF5B8DEF),
    Color(0xFF6C6CE5),
    Color(0xFF8F5BD9),
    Color(0xFFC254C4),
    Color(0xFFE2558F),
    Color(0xFFF06B5E),
    Color(0xFFF58A3D),
    Color(0xFFF2B33D),
    Color(0xFFD9B530),
  ],
  tileBeyond: Color(0xFF0B0C12),
  tileInkDark: Color(0xFF1F4D48),
);

/// Sand and shallow water to the deep, then coral and sun.
const _ocean = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFEAF4F7),
  surface: Color(0xFFFFFFFF),
  board: Color(0xFFD3E6EC),
  cell: Color(0xFFE2EFF3),
  ink: Color(0xFF143A4A),
  inkSoft: Color(0xFF5A7A87),
  accent: Color(0xFF1E8FB8),
  danger: Color(0xFFE5534B),
  success: Color(0xFF2FB38A),
  stone: Color(0xFF8E9DA3),
  stoneDark: Color(0xFF6F7E84),
  tiles: [
    Color(0xFFF2E3B8),
    Color(0xFF8EDCD6),
    Color(0xFF4FBCD1),
    Color(0xFF2EA3C7),
    Color(0xFF2183B5),
    Color(0xFF1F64A0),
    Color(0xFF27478A),
    Color(0xFF3D3577),
    Color(0xFFFF8A65),
    Color(0xFFFF6F61),
    Color(0xFFFFB938),
  ],
  tileBeyond: Color(0xFF0F2A38),
  tileInkDark: Color(0xFF14504F),
  darkTextOn: {2, 4},
);

/// Peach through coral to evening violet.
const _sunset = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFFFF1E6),
  surface: Color(0xFFFFFAF5),
  board: Color(0xFFF5DCCB),
  cell: Color(0xFFFBE8DA),
  ink: Color(0xFF4A2530),
  inkSoft: Color(0xFF8D6670),
  accent: Color(0xFF8E54C9),
  danger: Color(0xFFD7263D),
  success: Color(0xFF3DAE7B),
  stone: Color(0xFFA89A94),
  stoneDark: Color(0xFF877872),
  tiles: [
    Color(0xFFFFE7A8),
    Color(0xFFFFBA70),
    Color(0xFFFF9150),
    Color(0xFFFF7049),
    Color(0xFFF2545A),
    Color(0xFFDC4068),
    Color(0xFFC23372),
    Color(0xFFA02D7C),
    Color(0xFF7A2C82),
    Color(0xFF552C7E),
    Color(0xFF3A2B6E),
  ],
  tileBeyond: Color(0xFF24122A),
  tileInkDark: Color(0xFF7A3A12),
  darkTextOn: {2, 4},
);

/// Straw and young leaves to deep pine, then autumn gold.
const _forest = AppColors(
  brightness: Brightness.light,
  background: Color(0xFFEFF3E8),
  surface: Color(0xFFFBFDF7),
  board: Color(0xFFDCE5D0),
  cell: Color(0xFFE7EEDD),
  ink: Color(0xFF243B2A),
  inkSoft: Color(0xFF66786A),
  accent: Color(0xFF3E8E5B),
  danger: Color(0xFFD9534F),
  success: Color(0xFF2E9E6A),
  stone: Color(0xFF9A9A8E),
  stoneDark: Color(0xFF7B7B6F),
  tiles: [
    Color(0xFFF0E6B8),
    Color(0xFFA8D98A),
    Color(0xFF7CC576),
    Color(0xFF4FAE6E),
    Color(0xFF2F9468),
    Color(0xFF267A6A),
    Color(0xFF2B5F66),
    Color(0xFF8C6A3F),
    Color(0xFFB5833A),
    Color(0xFFD9A13A),
    Color(0xFFC9A227),
  ],
  tileBeyond: Color(0xFF1E2B22),
  tileInkDark: Color(0xFF2F4A1C),
  darkTextOn: {2, 4},
);

/// Glowing colors on a near-black board.
const _neon = AppColors(
  brightness: Brightness.dark,
  background: Color(0xFF0D0B1A),
  surface: Color(0xFF1A1630),
  board: Color(0xFF221D3D),
  cell: Color(0xFF2C264D),
  ink: Color(0xFFF1EEFF),
  inkSoft: Color(0xFF9C95C2),
  accent: Color(0xFFFF3EA5),
  coin: Color(0xFFFFD23F),
  coinEdge: Color(0xFFD9A514),
  danger: Color(0xFFFF4D4D),
  success: Color(0xFF2FE6A0),
  ice: Color(0xFF8AE9FF),
  stone: Color(0xFF5E5878),
  stoneDark: Color(0xFF47425E),
  tiles: [
    Color(0xFF3CF0E0),
    Color(0xFF7CFF6B),
    Color(0xFF2BB5FF),
    Color(0xFF6B6BFF),
    Color(0xFF9D4DFF),
    Color(0xFFD13CFF),
    Color(0xFFFF3EA5),
    Color(0xFFFF4D6D),
    Color(0xFFFF7A3D),
    Color(0xFFFFB13D),
    Color(0xFFFFE14D),
  ],
  tileBeyond: Color(0xFF05040C),
  tileInkDark: Color(0xFF15183A),
  darkTextOn: {2, 4, 1024, 2048},
);
