import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/ads/ad_service.dart';
import 'services/ads/yandex_ad_service.dart';
import 'services/audio/audio_service.dart';
import 'services/audio/music_service.dart';
import 'services/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final storage = await StorageService.open();
  final AdService ads = Platform.isAndroid || Platform.isIOS
      ? YandexAdService(storage)
      : NoAdService(storage);
  final audio = PooledAudioService();
  final music = PlayerMusicService();

  runApp(ProviderScope(
    overrides: [
      storageProvider.overrideWithValue(storage),
      adServiceProvider.overrideWithValue(ads),
      audioServiceProvider.overrideWithValue(audio),
      musicServiceProvider.overrideWithValue(music),
    ],
    child: const NumberFlowApp(),
  ));

  // None is required for the game to work; failures stay inside the services.
  // Music starts after the shared audio context is set.
  unawaited(audio.initialize().whenComplete(music.initialize));
  unawaited(ads.initialize());
}
