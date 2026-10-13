import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:papuy/platform/media_service.dart';

abstract class WindowService {
  static const _channel = MethodChannel('papuy/window');

  static final ValueNotifier<bool> inPip = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> playerOpen = ValueNotifier<bool>(false);
  static final ValueNotifier<int> homeRequests = ValueNotifier<int>(0);
  static final ValueNotifier<int> handoffRequests = ValueNotifier<int>(0);

  static void Function(String name)? onCommand;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pip') inPip.value = call.arguments == true;
      if (call.method == 'command' && call.arguments is String) {
        final name = call.arguments as String;
        if (name == 'home') {
          homeRequests.value++;
        } else if (name == 'handoff') {
          handoffRequests.value++;
        } else if (name == 'quickClosed') {
          MediaService.quickRequest.value = null;
        } else {
          onCommand?.call(name);
        }
      }
      return null;
    });
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
