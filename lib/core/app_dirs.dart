import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;

abstract class AppDirs {
  static const _channel = MethodChannel('papuy/paths');
  static String? _data;

  static Future<String> data() async {
    final cached = _data;
    if (cached != null) return cached;
    final paths = await _channel.invokeMapMethod<String, String>('resolve');
    final path = paths?['filesDir'] ?? Directory.systemTemp.path;
    await Directory(path).create(recursive: true);
    return _data = path;
  }

  static Future<String> downloads() => data();
}
