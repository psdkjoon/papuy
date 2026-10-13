import 'dart:collection';
import 'dart:typed_data';

import 'package:papuy/library/track_item.dart';
import 'package:papuy/platform/media_service.dart';

abstract class ArtCache {
  static const int _limit = 400;

  static final LinkedHashMap<String, Future<Uint8List?>> _cache =
      LinkedHashMap<String, Future<Uint8List?>>();

  static Future<Uint8List?> of(TrackItem track, {int size = 256}) {
    if (track.id < 0) return Future<Uint8List?>.value();
    final key = '${track.artKey}:$size';
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit;
      return hit;
    }
    final created = MediaService.albumArt(track.id, track.albumId, size);
    _cache[key] = created;
    while (_cache.length > _limit) {
      _cache.remove(_cache.keys.first);
    }
    return created;
  }
}
