import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:papuy/app.dart';
import 'package:papuy/core/diagnostics.dart';
import 'package:papuy/core/kv_store.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/platform/launcher_icon_service.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/platform/player_service.dart';
import 'package:papuy/platform/system_service.dart';
import 'package:papuy/platform/theme_sync_service.dart';
import 'package:papuy/platform/window_service.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Diagnostics.init();

  MediaService.init();
  WindowService.init();
  PlayerService.init();

  final store = await KvStore.open();
  final settings = AppSettings.load(store);
  await ThemeSyncService.adoptStored(settings);
  final library = LibraryController(settings, store);

  final music = MusicController(
    settings: settings,
    library: library,
    prefs: store,
  );

  runApp(PapuyApp(settings: settings, library: library, music: music));

  unawaited(SystemService.setQuickPlay(on: settings.quickPlay));
  settings.addListener(
    () => unawaited(SystemService.setQuickPlay(on: settings.quickPlay)),
  );

  unawaited(_initPlatform(settings));
}

Future<void> _initPlatform(AppSettings settings) async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } on Object {
    debugPrint('edge-to-edge unavailable');
  }

  LauncherIconService.init(settings);
  await ThemeSyncService.init(settings);
}
