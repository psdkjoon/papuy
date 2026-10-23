import 'package:flutter/foundation.dart';
import 'package:papuy/core/kv_store.dart';
import 'package:papuy/library/art_cache.dart';
import 'package:papuy/library/favorites.dart';
import 'package:papuy/library/video_filter.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/library/video_groups.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/library/watch_history.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/settings/music_sort.dart';
import 'package:papuy/settings/sort_key.dart';

enum LibraryStatus { loading, denied, ready, failed }

class LibraryController extends ChangeNotifier {
  LibraryController(this.settings, KvStore store)
      : _history = WatchHistory(store),
        _favorites = Favorites(store);

  final AppSettings settings;
  final WatchHistory _history;
  final Favorites _favorites;

  LibraryStatus status = LibraryStatus.loading;
  List<VideoItem> videos = const <VideoItem>[];
  List<TrackItem> tracks = const <TrackItem>[];
  Map<int, TrackItem> _trackIndex = const <int, TrackItem>{};

  void refresh() => notifyListeners();

  Future<void> load({bool ask = false}) async {
    status = LibraryStatus.loading;
    notifyListeners();
    ArtCache.clear();
    var granted = await MediaService.hasPermission();
    if (!granted && ask) granted = await MediaService.requestPermission();
    if (!granted) {
      status = LibraryStatus.denied;
      notifyListeners();
      return;
    }
    try {
      final rows = await MediaService.queryVideos();
      videos = <VideoItem>[for (final row in rows) VideoItem.fromMap(row)];
      status = LibraryStatus.ready;
    } on Object {
      status = LibraryStatus.failed;
    }
    try {
      final rows = await MediaService.queryAudio();
      tracks = <TrackItem>[for (final row in rows) TrackItem.fromMap(row)];
    } on Object {
      tracks = const <TrackItem>[];
    }
    _trackIndex = <int, TrackItem>{for (final t in tracks) t.id: t};
    notifyListeners();
  }

  TrackItem? trackById(int id) => _trackIndex[id];

  List<TrackItem> tracksByIds(Iterable<int> ids) {
    return <TrackItem>[
      for (final id in ids)
        if (_trackIndex[id] case final TrackItem track) track,
    ];
  }

  List<TrackItem> visibleTracks(String query) {
    final needle = query.trim().toLowerCase();
    final list = needle.isEmpty
        ? List<TrackItem>.of(tracks)
        : tracks.where((track) {
            return track.title.toLowerCase().contains(needle) ||
                track.artist.toLowerCase().contains(needle) ||
                track.album.toLowerCase().contains(needle);
          }).toList();
    int text(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    switch (settings.musicSort) {
      case MusicSort.title:
        list.sort((a, b) => text(a.title, b.title));
      case MusicSort.artist:
        list.sort((a, b) {
          final byArtist = text(a.artist, b.artist);
          return byArtist != 0 ? byArtist : text(a.title, b.title);
        });
      case MusicSort.added:
        list.sort((a, b) => b.added.compareTo(a.added));
      case MusicSort.duration:
        list.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    }
    return list;
  }

  String title(VideoItem video) =>
      settings.showExtensions ? video.name : video.nameWithoutExtension;

  bool isFavorite(VideoItem video) => _favorites.has(video.id);

  void toggleFavorite(VideoItem video) {
    _favorites.toggle(video.id);
    notifyListeners();
  }

  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }

  int position(VideoItem video) => _history.position(video.id);

  int lastPlayed(VideoItem video) => _history.lastPlayed(video.id);

  double? savedSpeed(VideoItem video) => _history.speed(video.id);

  double progress(VideoItem video) {
    if (video.durationMs <= 0) return 0;
    return (position(video) / video.durationMs).clamp(0.0, 1.0).toDouble();
  }

  void savePosition(VideoItem video, int ms) {
    _history.setPosition(video.id, ms);
  }

  void saveSpeed(VideoItem video, double speed) {
    _history.setSpeed(video.id, speed);
  }

  void markPlayed(VideoItem video) => _history.touch(video.id);

  void forgetPosition(VideoItem video) {
    _history.setPosition(video.id, 0);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  List<VideoItem> visible({
    required String query,
    required VideoFilter filter,
  }) {
    final needle = query.trim().toLowerCase();
    final weekAgo = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 7 * 86400;
    final list = videos.where((video) {
      if (!settings.showHidden && video.folder.startsWith('.')) return false;
      if (!video.name.toLowerCase().contains(needle)) return false;
      return switch (filter) {
        VideoFilter.all => true,
        VideoFilter.favorites => isFavorite(video),
        VideoFilter.continuing =>
          progress(video) > 0 && progress(video) < 1,
        VideoFilter.fresh => video.added >= weekAgo,
      };
    }).toList();
    switch (settings.sort) {
      case SortKey.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case SortKey.duration:
        list.sort((a, b) => b.durationMs.compareTo(a.durationMs));
      case SortKey.size:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case SortKey.played:
        list.sort((a, b) => lastPlayed(b).compareTo(lastPlayed(a)));
      case SortKey.date:
        list.sort((a, b) => b.added.compareTo(a.added));
    }
    return settings.sortAsc ? list.reversed.toList() : list;
  }

  Map<String, List<VideoItem>> folders(List<VideoItem> list) {
    final groups = groupByFolder(list);
    num score(String folder, List<VideoItem> items) {
      switch (settings.sort) {
        case SortKey.name:
          return 0;
        case SortKey.duration:
          return items.fold<int>(0, (sum, v) => sum + v.durationMs);
        case SortKey.size:
          return items.fold<int>(0, (sum, v) => sum + v.sizeBytes);
        case SortKey.played:
          return items.fold<int>(
            0,
            (best, v) => lastPlayed(v) > best ? lastPlayed(v) : best,
          );
        case SortKey.date:
          return items.fold<int>(0, (best, v) => v.added > best ? v.added : best);
      }
    }

    final entries = groups.entries.toList();
    if (settings.sort != SortKey.name) {
      entries.sort((a, b) {
        final byScore = score(b.key, b.value).compareTo(score(a.key, a.value));
        if (byScore != 0) return byScore;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    }
    final ordered = settings.sortAsc ? entries.reversed.toList() : entries;
    return <String, List<VideoItem>>{
      for (final entry in ordered) entry.key: entry.value,
    };
  }

  List<VideoItem> resumable() {
    final list = videos
        .where((video) => progress(video) > 0 && progress(video) < 1)
        .toList()
      ..sort((a, b) => lastPlayed(b).compareTo(lastPlayed(a)));
    return list;
  }
}
