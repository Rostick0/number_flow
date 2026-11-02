import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'game_themes.dart';

ThemeData buildAppTheme([GameTheme theme = GameTheme.classic]) {
  final AppColors c = theme.colors;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.accent,
    brightness: c.brightness,
    surface: c.surface,
  ).copyWith(primary: c.accent, onPrimary: Colors.white, onSurface: c.ink, error: c.danger);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: c.background,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: c.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: c.ink,
        side: BorderSide(color: c.board, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : null,
      ),
    ),
  );
}
