import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_flow/core/clock.dart';
import 'package:number_flow/core/day_key.dart';
import 'package:number_flow/features/achievements/achievements_screen.dart';
import 'package:number_flow/features/gameplay/game_controller.dart';
import 'package:number_flow/features/gameplay/game_screen.dart';
import 'package:number_flow/features/gameplay/saved_game.dart';
import 'package:number_flow/features/home/home_screen.dart';
import 'package:number_flow/features/profile/player_profile.dart';
import 'package:number_flow/features/profile/profile_controller.dart';
import 'package:number_flow/features/settings/app_settings.dart';
import 'package:number_flow/features/settings/settings_screen.dart';
import 'package:number_flow/features/shop/shop_screen.dart';
import 'package:number_flow/features/statistics/statistics_screen.dart';
import 'package:number_flow/game/models/bonus_type.dart';
import 'package:number_flow/services/storage/storage_service.dart';
import 'package:number_flow/shared/theme/app_theme.dart';
import 'package:number_flow/shared/theme/game_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 1, 12);

const _sizes = {
  'small phone': Size(320, 568),
  'phone': Size(390, 844),
  'tall phone': Size(412, 915),
  'tablet': Size(800, 1280),
  'short landscape-like': Size(640, 480),
};

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget home,
  Size size, {
  GameTheme theme = GameTheme.classic,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);

  final profile = PlayerProfile.fresh().copyWith(
    settings: const AppSettings(tutorialSeen: true),
    lastLoginClaimDay: dayKeyOf(_now),
  );
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({
    StorageService.profileKey: jsonEncode(profile.toJson()),
  });
  final storage = await StorageService.open();
  // Fake-async time: advances only with tester.pump.
  final start = tester.binding.clock.now();
  final container = ProviderContainer(overrides: [
    storageProvider.overrideWithValue(storage),
    clockProvider.overrideWithValue(() => _now.add(tester.binding.clock.now().difference(start))),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: buildAppTheme(theme), home: home),
  ));
  await tester.pump(const Duration(milliseconds: 500));
  return container;
}

/// Unmounts and disposes providers so the game loop timer stops before the
/// test ends.
Future<void> _unmount(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('home fits on ${entry.key}', (tester) async {
      final container = await _pump(tester, const HomeScreen(), entry.value);
      expect(find.text('Number Flow'), findsOneWidget);
      expect(find.text('Играть'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester, container);
    });

    testWidgets('game screen fits on ${entry.key}', (tester) async {
      final container =
          await _pump(tester, const GameScreen(launch: GameLaunch('time_attack')), entry.value);
      expect(find.text('СЧЁТ'), findsOneWidget);
      expect(find.text('ДАЛЕЕ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester, container);
    });

    testWidgets('secondary screens fit on ${entry.key}', (tester) async {
      for (final screen in const [
        ShopScreen(),
        AchievementsScreen(),
        StatisticsScreen(),
        SettingsScreen(),
      ]) {
        final container = await _pump(tester, screen, entry.value);
        expect(tester.takeException(), isNull);
        await _unmount(tester, container);
      }
    });
  }

  for (final theme in GameTheme.values) {
    testWidgets('game screen renders in the ${theme.name} theme', (tester) async {
      final container = await _pump(
        tester,
        const GameScreen(launch: GameLaunch('classic')),
        const Size(390, 844),
        theme: theme,
      );
      expect(find.text('ДАЛЕЕ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester, container);
    });
  }

  testWidgets('a locked theme is bought from its card', (tester) async {
    final container = await _pump(tester, const SettingsScreen(), const Size(390, 844));
    for (final theme in GameTheme.values) {
      expect(find.text(theme.title), findsOneWidget);
    }
    final buy = find.widgetWithText(FilledButton, '${GameTheme.night.price}');

    // Starting coins are not enough: the offer opens with buying disabled.
    await tester.tap(find.text(GameTheme.night.title));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<FilledButton>(buy).onPressed, isNull);
    await tester.tap(find.text('Отмена'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(profileProvider).settings.theme, GameTheme.classic);

    container.read(profileProvider.notifier).addCoins(GameTheme.night.price);
    final coins = container.read(profileProvider).coins;
    await tester.tap(find.text(GameTheme.night.title));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(buy);
    await tester.pump(const Duration(milliseconds: 300));
    final p = container.read(profileProvider);
    expect(p.settings.theme, GameTheme.night);
    expect(p.coins, coins - GameTheme.night.price);
    expect(find.text('Выбрана'), findsOneWidget);

    await tester.tap(find.text(GameTheme.classic.title));
    await tester.pump();
    expect(container.read(profileProvider).settings.theme, GameTheme.classic);
    await tester.pump(const Duration(seconds: 3));
    await _unmount(tester, container);
  });

  testWidgets('pause overlay opens and resumes', (tester) async {
    final container =
        await _pump(tester, const GameScreen(launch: GameLaunch('classic')), const Size(390, 844));
    await tester.tap(find.byTooltip('Пауза'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Пауза'), findsWidgets);
    await tester.tap(find.text('Продолжить'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Продолжить'), findsNothing);
    await _unmount(tester, container);
  });

  testWidgets('using a bonus spends it from the inventory', (tester) async {
    final container =
        await _pump(tester, const GameScreen(launch: GameLaunch('classic')), const Size(390, 844));
    final before = container.read(profileProvider).bonusCount(BonusType.slowMotion);
    await tester.tap(find.text('Slow'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(profileProvider).bonusCount(BonusType.slowMotion), before - 1);
    expect(
      container.read(gameControllerProvider(const GameLaunch('classic'))).slowSecondsLeft,
      greaterThan(0),
    );
    await _unmount(tester, container);
  });

  testWidgets('an idle game overflows, shows results and is recorded', (tester) async {
    const launch = GameLaunch('classic');
    final container = await _pump(tester, const GameScreen(launch: launch), const Size(390, 844));
    for (var i = 0; i < 800 && find.text('Поле переполнено').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.text('Поле переполнено'), findsOneWidget);
    expect(find.text('Ещё раз'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final profile = container.read(profileProvider);
    expect(profile.stats.gamesPlayed, 1);
    expect(container.read(savedGameRepositoryProvider).load(), isNull);

    await tester.tap(find.text('Ещё раз'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Поле переполнено'), findsNothing);
    expect(container.read(gameControllerProvider(launch)).isOver, isFalse);
    await _unmount(tester, container);
  });

  testWidgets('leaving a game keeps it resumable', (tester) async {
    const launch = GameLaunch('classic');
    final container = await _pump(tester, const GameScreen(launch: launch), const Size(390, 844));
    await tester.pump(const Duration(seconds: 5));
    final score = container.read(gameControllerProvider(launch)).score;
    await tester.tap(find.byTooltip('Пауза'));
    await tester.pump(const Duration(milliseconds: 300));
    final saved = container.read(savedGameRepositoryProvider).load();
    expect(saved, isNotNull);
    expect(saved!.modeId, 'classic');
    expect(saved.score, score);
    await _unmount(tester, container);
  });
}
