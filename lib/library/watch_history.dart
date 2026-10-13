import 'dart:convert';

import 'package:papuy/core/kv_store.dart';

class WatchHistory {
  WatchHistory(this._store) {
    _positions = _readMap('positions');
    _lastPlayed = _readMap('lastPlayed');
    _speeds = _readMap('speeds');
  }

  final KvStore _store;
  late final Map<String, num> _positions;
  late final Map<String, num> _lastPlayed;
  late final Map<String, num> _speeds;

  int position(int id) => _positions['$id']?.toInt() ?? 0;

  int lastPlayed(int id) => _lastPlayed['$id']?.toInt() ?? 0;

  double? speed(int id) => _speeds['$id']?.toDouble();

  void setPosition(int id, int ms) {
    if (ms <= 0) {
      _positions.remove('$id');
    } else {
      _positions['$id'] = ms;
    }
    _write('positions', _positions);
  }

  void setSpeed(int id, double speed) {
    _speeds['$id'] = speed;
    _write('speeds', _speeds);
  }

  void touch(int id) {
    _lastPlayed['$id'] = DateTime.now().millisecondsSinceEpoch;
    _write('lastPlayed', _lastPlayed);
  }

  void clear() {
    _positions.clear();
    _lastPlayed.clear();
    _speeds.clear();
    _write('positions', _positions);
    _write('lastPlayed', _lastPlayed);
    _write('speeds', _speeds);
  }

  Map<String, num> _readMap(String key) {
    final raw = _store.getString(key);
    final result = <String, num>{};
    if (raw == null) return result;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is num) result[entry.key] = value;
        }
      }
    } on FormatException {
      return result;
    }
    return result;
  }

  void _write(String key, Map<String, num> map) {
    _store.setString(key, jsonEncode(map));
  }
}
