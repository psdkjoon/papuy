import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:papuy/library/track_item.dart';
import 'package:papuy/platform/media_service.dart';

abstract class ArtCache {
  static const int _limit = 400;

  static final LinkedHashMap<String, Future<Uint8List?>> _cache =
      LinkedHashMap<String, Future<Uint8List?>>();

  static void clear() => _cache.clear();

  static Future<Uint8List?> of(TrackItem track, {int size = 256}) {
    final key = 't${track.id}:$size';
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit;
      return hit;
    }
    final created =
        MediaService.albumArt(track.id, track.albumId, size, track.uri);
    _cache[key] = created;
    unawaited(
      created.then((bytes) {
        if (bytes == null && identical(_cache[key], created)) {
          _cache.remove(key);
        }
      }),
    );
    while (_cache.length > _limit) {
      _cache.remove(_cache.keys.first);
    }
    return created;
  }
}
