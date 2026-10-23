import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:papuy/platform/media_service.dart';

abstract class WindowService {
  static const _channel = MethodChannel('papuy/window');

  static final ValueNotifier<bool> inPip = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> playerOpen = ValueNotifier<bool>(false);
  static final ValueNotifier<int> homeRequests = ValueNotifier<int>(0);
  static final ValueNotifier<int> handoffRequests = ValueNotifier<int>(0);
  static final ValueNotifier<int> playerRequests = ValueNotifier<int>(0);
  static bool playerRequested = false;

  static void Function(String name)? _handler;
  static String? startupCommand;

  static set onCommand(void Function(String name)? handler) {
    _handler = handler;
    final waiting = startupCommand;
    if (handler != null && waiting != null) {
      startupCommand = null;
      handler(waiting);
    }
  }

  static void Function(String name)? get onCommand => _handler;

  static void _dispatch(String name) {
    final handler = _handler;
    if (handler == null) {
      startupCommand = name;
    } else {
      handler(name);
    }
  }

  static void _command(String name) {
    if (name == 'home') {
      homeRequests.value++;
    } else if (name == 'handoff') {
      handoffRequests.value++;
    } else if (name == 'openPlayer') {
      playerRequested = true;
      playerRequests.value++;
    } else if (name == 'quickClosed') {
      MediaService.quickRequest.value = null;
    } else {
      _dispatch(name);
    }
  }

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pip') inPip.value = call.arguments == true;
      if (call.method == 'command' && call.arguments is String) {
        _command(call.arguments as String);
      }
      return null;
    });
    unawaited(_announceReady());
  }

  static Future<void> _announceReady() async {
    final waiting = await _call<String>('ready');
    if (waiting != null && waiting.isNotEmpty) _command(waiting);
  }

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    }
  }

  static Future<double> getBrightness() async =>
      await _call<double>('getBrightness') ?? 0.5;

  static Future<void> setBrightness(double value) =>
      _call<void>('setBrightness', <String, double>{'value': value});

  static Future<double> getVolume() async =>
      await _call<double>('getVolume') ?? 0.5;

  static Future<void> setVolume(double value) =>
      _call<void>('setVolume', <String, double>{'value': value});

  static Future<void> keepAwake({required bool on}) =>
      _call<void>('keepAwake', <String, bool>{'on': on});

  static Future<void> enterPip(int width, int height, {bool buttons = true}) =>
      _call<void>('enterPip', <String, Object>{
        'width': width,
        'height': height,
        'buttons': buttons,
      });

  static Future<void> setAutoPip({
    required bool on,
    required int width,
    required int height,
    bool buttons = true,
  }) =>
      _call<void>('setAutoPip', <String, Object>{
        'on': on,
        'width': width,
        'height': height,
        'buttons': buttons,
      });

  static Future<void> setBackground({
    required bool on,
    String title = '',
    bool playing = true,
    bool music = false,
    String artist = '',
    String album = '',
    int durationMs = 0,
    int positionMs = 0,
    bool shuffle = false,
    int repeat = 0,
    double speed = 1.0,
    bool artChanged = false,
    Uint8List? art,
  }) =>
      _call<void>('setBackground', <String, Object?>{
        'on': on,
        'title': title,
        'playing': playing,
        'music': music,
        'artist': artist,
        'album': album,
        'durationMs': durationMs,
        'positionMs': positionMs,
        'shuffle': shuffle,
        'repeat': repeat,
        'speed': speed,
        'artChanged': artChanged,
        'art': art,
      });
}
