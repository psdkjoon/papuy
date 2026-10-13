import 'package:flutter/services.dart';
import 'package:papuy/player/player_info.dart';
import 'package:papuy/player/track_option.dart';

abstract class PlayerService {
  static const _channel = MethodChannel('papuy/player');

  static void Function()? onCompleted;
  static void Function(int width, int height, double ratio, int rotation)?
      onSize;
  static void Function(List<TrackOption> tracks)? onTracks;
  static void Function(String text)? onCue;
  static void Function(String code)? onError;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      final arguments = call.arguments;
      switch (call.method) {
        case 'completed':
          onCompleted?.call();
        case 'size':
          if (arguments is Map<Object?, Object?>) {
            onSize?.call(
              (arguments['width'] as num?)?.toInt() ?? 0,
              (arguments['height'] as num?)?.toInt() ?? 0,
              (arguments['ratio'] as num?)?.toDouble() ?? 1.0,
              (arguments['rotation'] as num?)?.toInt() ?? 0,
            );
          }
        case 'tracks':
          onTracks?.call(TrackOption.parseList(arguments));
        case 'cue':
          onCue?.call(arguments is String ? arguments : '');
        case 'error':
          onError?.call(arguments is String ? arguments : 'error');
      }
      return null;
    });
  }

  static Future<PlayerInfo> open({
    required String uri,
    required int startMs,
    required double speed,
    required bool boost,
    required bool play,
    required String audioLang,
    required String subtitleLang,
    required bool skipSilence,
    required bool exactSeek,
    required bool pauseNoisy,
    bool audio = false,
  }) async {
    final map = await _channel.invokeMapMethod<String, Object?>(
      'open',
      <String, Object>{
        'uri': uri,
        'startMs': startMs,
        'speed': speed,
        'boost': boost,
        'play': play,
        'audioLang': audioLang,
        'subtitleLang': subtitleLang,
        'skipSilence': skipSilence,
        'exactSeek': exactSeek,
        'pauseNoisy': pauseNoisy,
        'audio': audio,
      },
    );
    if (map == null) throw PlatformException(code: 'open_failed');
    return PlayerInfo.fromMap(map);
  }

  static Future<void> _simple(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      return;
    }
  }

  static Future<void> play() => _simple('play');

  static Future<void> pause() => _simple('pause');

  static Future<void> seek(int ms) =>
      _simple('seek', <String, int>{'ms': ms});

  static Future<void> setSpeed(double speed) =>
      _simple('speed', <String, double>{'value': speed});

  static Future<void> mute({required bool on}) =>
      _simple('mute', <String, bool>{'on': on});

  static Future<void> selectTrack(String type, int group, int index) =>
      _simple('selectTrack', <String, Object>{
        'type': type,
        'group': group,
        'index': index,
      });

  static Future<void> close() => _simple('close');

  static Future<Uint8List?> bands() async {
    try {
      return await _channel.invokeMethod<Uint8List>('bands');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<PlayerSnapshot?> snapshot() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>('state');
      if (map == null) return null;
      return PlayerSnapshot(
        positionMs: (map['pos'] as num?)?.toInt() ?? 0,
        playing: map['playing'] == true,
        buffering: map['buffering'] == true,
        durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      );
    } on PlatformException {
      return null;
    }
  }
}
