import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:papuy/core/kv_store.dart';

class Playlist {
  Playlist({required this.id, required this.name, List<int>? tracks})
      : tracks = tracks ?? <int>[];

  factory Playlist.fromJson(Map<String, Object?> json) {
    final raw = json['tracks'];
    return Playlist(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      tracks: raw is List ? raw.whereType<num>().map((e) => e.toInt()).toList() : null,
    );
  }

  final String id;
  String name;
  final List<int> tracks;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'tracks': tracks,
      };
}

class MusicStore extends ChangeNotifier {
  MusicStore(this._store) {
    _readPlaylists();
    final saved = _store.getStringList('trackFavorites') ?? const <String>[];
    for (final item in saved) {
      final id = int.tryParse(item);
      if (id != null) _favorites.add(id);
    }
    _readHistory();
  }

  final KvStore _store;
  final List<Playlist> playlists = <Playlist>[];
  final Set<int> _favorites = <int>{};
  final Map<int, int> _plays = <int, int>{};
  final Map<int, int> _last = <int, int>{};

  Set<int> get favorites => _favorites;

  bool isFavorite(int id) => _favorites.contains(id);

  int plays(int id) => _plays[id] ?? 0;

  int lastPlayed(int id) => _last[id] ?? 0;

  Iterable<int> get playedIds => _last.keys;

  Playlist? byId(String id) {
    for (final playlist in playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  void toggleFavorite(int id) {
    if (id < 0) return;
    if (!_favorites.remove(id)) _favorites.add(id);
    _store.setStringList('trackFavorites', [for (final x in _favorites) '$x']);
    notifyListeners();
  }

  void markPlayed(int id) {
    if (id < 0) return;
    _plays[id] = plays(id) + 1;
    _last[id] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _writeHistory();
    notifyListeners();
  }

  void clearHistory() {
    _plays.clear();
    _last.clear();
    _writeHistory();
    notifyListeners();
  }

  Playlist create(String name, [List<int> tracks = const <int>[]]) {
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: name.trim(),
      tracks: <int>[...tracks.where((id) => id >= 0)],
    );
    playlists.add(playlist);
    _writePlaylists();
    return playlist;
  }

  void rename(Playlist playlist, String name) {
    playlist.name = name.trim();
    _writePlaylists();
  }

  void delete(Playlist playlist) {
    playlists.remove(playlist);
    _writePlaylists();
  }

  int addAll(Playlist playlist, Iterable<int> ids) {
    var added = 0;
    for (final id in ids) {
      if (id < 0 || playlist.tracks.contains(id)) continue;
      playlist.tracks.add(id);
      added++;
    }
    if (added > 0) _writePlaylists();
    return added;
  }

  void removeFrom(Playlist playlist, int id) {
    playlist.tracks.remove(id);
    _writePlaylists();
  }

  void move(Playlist playlist, int from, int to) {
    if (from < 0 || from >= playlist.tracks.length) return;
    final id = playlist.tracks.removeAt(from);
    playlist.tracks.insert(to.clamp(0, playlist.tracks.length).toInt(), id);
    _writePlaylists();
  }

  void _readPlaylists() {
    final text = _store.getString('playlists');
    if (text == null) return;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return;
      for (final item in decoded) {
        if (item is Map) {
          playlists.add(Playlist.fromJson(Map<String, Object?>.from(item)));
        }
      }
    } on Object {
      playlists.clear();
    }
  }

  void _writePlaylists() {
    _store.setString(
      'playlists',
      jsonEncode([for (final playlist in playlists) playlist.toJson()]),
    );
    notifyListeners();
  }

  void _readHistory() {
    final text = _store.getString('trackHistory');
    if (text == null) return;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        final id = int.tryParse('${entry.key}');
        final value = entry.value;
        if (id == null || value is! List || value.length < 2) continue;
        _plays[id] = (value[0] as num).toInt();
        _last[id] = (value[1] as num).toInt();
      }
    } on Object {
      _plays.clear();
      _last.clear();
    }
  }

  void _writeHistory() {
    _store.setString(
      'trackHistory',
      jsonEncode(<String, Object?>{
        for (final id in _last.keys) '$id': <int>[plays(id), lastPlayed(id)],
      }),
    );
  }
}
