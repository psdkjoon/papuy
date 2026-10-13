import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef IncomingVideo = ({String uri, String name, bool quick, String mime});

abstract class MediaService {
  static const _channel = MethodChannel('papuy/media');

  static final ValueNotifier<IncomingVideo?> incoming =
      ValueNotifier<IncomingVideo?>(null);

  static final ValueNotifier<IncomingVideo?> quickRequest =
      ValueNotifier<IncomingVideo?>(null);

  static IncomingVideo? handoff;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'intent') incoming.value = _parse(call.arguments);
      return null;
    });
  }

  static IncomingVideo? _parse(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final uri = raw['uri'];
    if (uri is! String) return null;
    final name = raw['name'];
    return (
      uri: uri,
      name: name is String ? name : uri,
      quick: raw['quick'] == '1',
      mime: raw['mime'] is String ? raw['mime'] as String : '',
    );
  }

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> hasPermission() async =>
      await _call<bool>('hasPermission') ?? false;

  static Future<bool> requestPermission() async =>
      await _call<bool>('requestPermission') ?? false;

  static Future<List<Map<Object?, Object?>>> queryVideos() async {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'queryVideos',
    );
    return rows ?? <Map<Object?, Object?>>[];
  }

  static Future<List<Map<Object?, Object?>>> queryAudio() async {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'queryAudio',
    );
    return rows ?? <Map<Object?, Object?>>[];
  }

  static Future<Uint8List?> albumArt(int id, int albumId, int size) =>
      _call<Uint8List>('albumArt', <String, int>{
        'id': id,
        'albumId': albumId,
        'size': size,
      });

  static Future<Uint8List?> thumbnail(int id) =>
      _call<Uint8List>('thumbnail', <String, int>{
        'id': id,
        'width': 320,
        'height': 180,
      });

  static Future<IncomingVideo?> takeLaunch() async =>
      _parse(await _call<Map<Object?, Object?>>('takeLaunch'));

  static Future<bool> share(String uri, {String type = 'video/*'}) async =>
      await _call<bool>('share', <String, String>{'uri': uri, 'type': type}) ??
      false;

  static Future<bool> delete(String uri) async =>
      await _call<bool>('delete', <String, String>{'uri': uri}) ?? false;

  static Future<bool> screenshot(String uri, int positionMs) async =>
      await _call<bool>('screenshot', <String, Object>{
        'uri': uri,
        'positionMs': positionMs,
      }) ??
      false;

  static Future<String?> pickSubtitle() => _call<String>('pickSubtitle');

  static Future<({String name, String text})?> pickPlaylist() async {
    final map = await _call<Map<Object?, Object?>>('pickPlaylist');
    if (map == null) return null;
    final text = map['text'];
    if (text is! String) return null;
    return (name: (map['name'] as String?) ?? '', text: text);
  }
}
