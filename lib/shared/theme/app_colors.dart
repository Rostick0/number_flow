import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF4F1EA);
  static const surface = Color(0xFFFFFFFF);
  static const board = Color(0xFFE6E0D4);
  static const cell = Color(0xFFEFEAE1);
  static const ink = Color(0xFF2B2D42);
  static const inkSoft = Color(0xFF6B6E80);
  static const accent = Color(0xFF5B6CFF);
  static const coin = Color(0xFFF2B33D);
  static const danger = Color(0xFFE5534B);
  static const success = Color(0xFF3DBE8B);
  static const ice = Color(0xFFBFE6FF);
  static const stone = Color(0xFF9AA0A6);
  static const stoneDark = Color(0xFF7D838A);
}

/// Cool-to-warm progression: each doubling moves one step along the wheel.
class TilePalette {
  static const _colors = <Color>[
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
  ];
  static const _beyond = Color(0xFF2B2D42);

  static int _index(int value) {
    var i = 0;
    var v = value;
    while (v > 2) {
      v >>= 1;
      i++;
    }
    return i;
  }

  static Color colorFor(int value) {
    final i = _index(value);
    return i < _colors.length ? _colors[i] : _beyond;
  }

  static Color textFor(int value) {
    if (value == 2) return const Color(0xFF1F4D48);
    if (_index(value) >= _colors.length) return AppColors.coin;
    return Colors.white;
  }

  /// Darker shade used for the tile's bottom edge.
  static Color edgeFor(Color c) =>
      Color.lerp(c, Colors.black, 0.18)!;
}
