import 'package:papuy/core/kv_store.dart';

class Favorites {
  Favorites(this._store) {
    final saved = _store.getStringList('favorites') ?? const <String>[];
    for (final item in saved) {
      final id = int.tryParse(item);
      if (id != null) _ids.add(id);
    }
  }

  final KvStore _store;
  final Set<int> _ids = <int>{};

  bool has(int id) => _ids.contains(id);

  void toggle(int id) {
    if (!_ids.remove(id)) _ids.add(id);
    _write();
  }

  void clear() {
    _ids.clear();
    _write();
  }

  void _write() {
    _store.setStringList('favorites', [for (final id in _ids) '$id']);
  }
}
