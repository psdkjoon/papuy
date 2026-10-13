import 'dart:typed_data';

import 'package:papuy/platform/media_service.dart';

abstract class ThumbnailCache {
  static final Map<int, Future<Uint8List?>> _cache =
      <int, Future<Uint8List?>>{};

  static Future<Uint8List?> of(int id) {
    if (id < 0) return Future<Uint8List?>.value();
    return _cache.putIfAbsent(id, () => MediaService.thumbnail(id));
  }
}
