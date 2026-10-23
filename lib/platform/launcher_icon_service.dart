import 'dart:async';

import 'package:flutter/services.dart';
import 'package:papuy/settings/app_settings.dart';

abstract class LauncherIconService {
  static const _channel = MethodChannel('papuy/launcher_icon');
  static AppSettings? _settings;
  static String? _sent;

  static void init(AppSettings settings) {
    if (_settings != null) return;
    _settings = settings;
    settings.addListener(_push);
    unawaited(_push());
  }

  static Future<void> _push() async {
    final settings = _settings;
    if (settings == null) return;
    final mode = settings.themeMode.name;
    final key = '$mode|${settings.accent}|${settings.appearanceUpdatedAt}';
    if (key == _sent) return;
    _sent = key;
    try {
      await _channel.invokeMethod<void>('configure', {
        'mode': mode,
        'accent': settings.accent,
        'updatedAt': settings.appearanceUpdatedAt,
      });
    } on PlatformException {
      _sent = null;
    } on MissingPluginException {
      _sent = null;
    }
  }
}
