import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';
import 'features/profile/profile_controller.dart';
import 'services/audio/music_service.dart';
import 'shared/theme/app_theme.dart';

class NumberFlowApp extends ConsumerStatefulWidget {
  const NumberFlowApp({super.key});

  @override
  ConsumerState<NumberFlowApp> createState() => _NumberFlowAppState();
}

class _NumberFlowAppState extends ConsumerState<NumberFlowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(musicServiceProvider).setEnabled(ref.read(profileProvider).settings.music);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Daily quests and the daily challenge roll over at local midnight.
    if (state == AppLifecycleState.resumed) {
      ref.read(profileProvider.notifier).refreshDay();
    }
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(musicServiceProvider).setForeground(true);
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        ref.read(musicServiceProvider).setForeground(false);
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider.select((p) => p.settings.music),
        (_, on) => ref.read(musicServiceProvider).setEnabled(on));
    return MaterialApp(
      title: 'Number Flow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
    );
  }
}
