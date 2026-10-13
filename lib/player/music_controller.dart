import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:papuy/core/kv_store.dart';
import 'package:papuy/library/art_cache.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/music_store.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/platform/player_service.dart';
import 'package:papuy/platform/window_service.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/settings/loop_mode.dart';

class MusicController extends ChangeNotifier {
  MusicController({
    required this.settings,
    required this.library,
    required KvStore prefs,
  })  : _prefs = prefs,
        data = MusicStore(prefs),
        shuffle = settings.musicShuffle,
        repeat = settings.musicRepeat {
    WindowService.playerOpen.addListener(_onVideoOpened);
    WindowService.onCommand = _onCommand;
    library.addListener(_maybeRestore);
  }

  static const Duration _restartThreshold = Duration(seconds: 3);
  static const Duration _pollEvery = Duration(milliseconds: 500);

  final AppSettings settings;
  final LibraryController library;
  final MusicStore data;
  final KvStore _prefs;
  final math.Random _random = math.Random();

  List<TrackItem> _original = <TrackItem>[];
  List<TrackItem> queue = <TrackItem>[];
  int index = -1;

  bool shuffle;
  LoopMode repeat;
  bool loading = false;
  bool failed = false;
  bool playing = false;
  Duration position = Duration.zero;
  int durationMs = 0;
  double speed = 1.0;
  DateTime? sleepAt;
  int sleepTotalSeconds = 0;
  bool dragging = false;

  Timer? _poller;
  int _generation = 0;
  bool _disposed = false;
  bool _restored = false;
  bool _pendingOpen = false;
  int _ticks = 0;

  bool get hasTrack => index >= 0 && index < queue.length;
  void haptic() {
    if (settings.haptics) unawaited(HapticFeedback.selectionClick());
  }

  TrackItem? get track => hasTrack ? queue[index] : null;
  Duration? get sleepLeft {
    final at = sleepAt;
    if (at == null) return null;
    final left = at.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  double get sleepProgress {
    final left = sleepLeft;
    if (left == null || sleepTotalSeconds <= 0) return 0;
    return (left.inMilliseconds / (sleepTotalSeconds * 1000))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  bool get hasNext => index < queue.length - 1;
  bool get hasPrevious => index > 0;

  String get speedLabel {
    final text = speed.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poller?.cancel();
    WindowService.playerOpen.removeListener(_onVideoOpened);
    library.removeListener(_maybeRestore);
    if (WindowService.onCommand == _onCommand) WindowService.onCommand = null;
    super.dispose();
  }

  void _maybeRestore() {
    if (_restored || library.status != LibraryStatus.ready) return;
    _restored = true;
    if (!settings.musicRestore || hasTrack || WindowService.playerOpen.value) {
      return;
    }
    final ids = (_prefs.getStringList('musicQueue') ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final items = library.tracksByIds(ids);
    if (items.isEmpty) return;
    final saved = _prefs.getInt('musicIndex') ?? 0;
    final wanted = saved >= 0 && saved < ids.length ? ids[saved] : ids.first;
    final at = items.indexWhere((item) => item.id == wanted);
    queue = items;
    _original = List<TrackItem>.of(items);
    index = at < 0 ? 0 : at;
    position = Duration(milliseconds: _prefs.getInt('musicPosition') ?? 0);
    durationMs = queue[index].durationMs;
    playing = false;
    _pendingOpen = true;
    notifyListeners();
  }

  void _persist() {
    if (!hasTrack || queue.any((item) => item.isExternal)) return;
    _prefs.setStringList('musicQueue', [for (final item in queue) '${item.id}']);
    _prefs.setInt('musicIndex', index);
    _prefs.setInt('musicPosition', position.inMilliseconds);
  }

  void _forgetQueue() {
    _prefs.remove('musicQueue');
    _prefs.remove('musicIndex');
    _prefs.remove('musicPosition');
  }

  Future<void> playQueue(List<TrackItem> tracks, int start) async {
    if (tracks.isEmpty) return;
    _original = List<TrackItem>.of(tracks);
    final first = tracks[start.clamp(0, tracks.length - 1).toInt()];
    if (shuffle) {
      queue = _shuffled(_original, first);
      index = 0;
    } else {
      queue = List<TrackItem>.of(_original);
      index = queue.indexOf(first);
    }
    await _open();
  }

  Future<void> playShuffled(List<TrackItem> tracks) async {
    if (tracks.isEmpty) return;
    if (!shuffle) setShuffle(true);
    await playQueue(tracks, _random.nextInt(tracks.length));
  }

  Future<void> playSingle(TrackItem item) => playQueue(<TrackItem>[item], 0);

  List<TrackItem> _shuffled(List<TrackItem> source, TrackItem first) {
    final rest = source.where((item) => item != first).toList()
      ..shuffle(_random);
    return <TrackItem>[first, ...rest];
  }

  void setShuffle(bool value) {
    if (shuffle == value) return;
    shuffle = value;
    settings.musicShuffle = value;
    final current = track;
    if (current != null) {
      if (value) {
        queue = _shuffled(queue, current);
        index = 0;
      } else {
        final keep = queue.toSet();
        queue = _original.where(keep.contains).toList();
        index = queue.indexOf(current);
      }
    }
    notifyListeners();
    _sync();
  }

  void toggleShuffle() => setShuffle(!shuffle);

  void cycleRepeat() {
    repeat = repeat.next;
    settings.musicRepeat = repeat;
    notifyListeners();
    _sync();
  }

  Future<void> _open({int startMs = 0}) async {
    final item = track;
    if (item == null) return;
    _pendingOpen = false;
    final generation = ++_generation;
    loading = true;
    failed = false;
    position = Duration(milliseconds: startMs);
    durationMs = item.durationMs;
    notifyListeners();
    PlayerService.onCompleted = _onCompleted;
    PlayerService.onError = _onError;
    PlayerService.onSize = null;
    PlayerService.onTracks = null;
    PlayerService.onCue = null;
    try {
      final opened = await PlayerService.open(
        uri: item.uri,
        startMs: startMs,
        speed: speed,
        boost: settings.volumeBoost,
        play: true,
        audioLang: 'auto',
        subtitleLang: 'off',
        skipSilence: settings.skipSilence,
        exactSeek: false,
        pauseNoisy: settings.pauseNoisy,
        audio: true,
      );
      if (generation != _generation || _disposed) return;
      if (opened.durationMs > 0) durationMs = opened.durationMs;
      loading = false;
      playing = true;
      data.markPlayed(item.id);
      _persist();
      _startPolling();
      unawaited(_syncBackground(withArt: true));
      notifyListeners();
    } on Object {
      if (generation != _generation || _disposed) return;
      loading = false;
      failed = true;
      playing = false;
      notifyListeners();
      if (hasNext) {
        Future<void>.delayed(const Duration(seconds: 1), () {
          if (generation == _generation && failed && hasNext) {
            unawaited(next());
          }
        });
      }
    }
  }

  void _sync() {
    if (hasTrack && !loading) unawaited(_syncBackground());
  }

  Future<void> _syncBackground({bool withArt = false}) async {
    final item = track;
    if (item == null) return WindowService.setBackground(on: false);
    Uint8List? art;
    if (withArt) art = await ArtCache.of(item, size: 320);
    if (_disposed || track != item) return;
    await WindowService.setBackground(
      on: true,
      title: item.title,
      music: true,
      artist: item.artist,
      album: item.album,
      durationMs: durationMs,
      positionMs: position.inMilliseconds,
      playing: playing,
      shuffle: shuffle,
      repeat: repeat.index,
      speed: speed,
      artChanged: withArt,
      art: art,
    );
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(_pollEvery, (_) => _poll());
  }

  bool _polling = false;

  Future<void> _poll() async {
    if (_polling || _disposed || !hasTrack || loading) return;
    _polling = true;
    final snapshot = await PlayerService.snapshot();
    _polling = false;
    if (snapshot == null || _disposed) return;
    final sleep = sleepAt;
    final wasPlaying = playing;
    if (sleep != null && DateTime.now().isAfter(sleep)) {
      sleepAt = null;
      sleepTotalSeconds = 0;
      await PlayerService.pause();
      playing = false;
    } else {
      playing = snapshot.playing;
    }
    if (wasPlaying != playing) _sync();
    if (!dragging) {
      position = Duration(milliseconds: snapshot.positionMs);
    }
    if (snapshot.durationMs > 0) durationMs = snapshot.durationMs;
    if (++_ticks % 10 == 0) _persist();
    notifyListeners();
  }

  void _onCompleted() {
    unawaited(next(automatic: true));
  }

  void _onError(String code) {
    failed = true;
    playing = false;
    notifyListeners();
  }

  void _onCommand(String name) {
    if (!hasTrack) return;
    switch (name) {
      case 'next':
        unawaited(next());
      case 'previous':
        unawaited(previous());
      case 'shuffle':
        toggleShuffle();
      case 'repeat':
        cycleRepeat();
      case 'stop':
        unawaited(stop());
    }
  }

  void _onVideoOpened() {
    if (WindowService.playerOpen.value && hasTrack) unawaited(stop());
  }

  Future<void> togglePlay() async {
    if (!hasTrack || loading) return;
    if (_pendingOpen) {
      await _open(startMs: position.inMilliseconds);
      return;
    }
    if (failed) {
      await _open();
      return;
    }
    if (playing) {
      await PlayerService.pause();
      playing = false;
    } else {
      if (durationMs > 0 && position.inMilliseconds >= durationMs - 500) {
        await PlayerService.seek(0);
        position = Duration.zero;
      }
      await PlayerService.play();
      playing = true;
    }
    notifyListeners();
    _sync();
  }

  Future<void> next({bool automatic = false}) async {
    if (!hasTrack) return;
    if (automatic && repeat == LoopMode.one) {
      await PlayerService.seek(0);
      await PlayerService.play();
      position = Duration.zero;
      playing = true;
      notifyListeners();
      _sync();
      return;
    }
    if (hasNext) {
      index++;
      await _open();
    } else if (repeat == LoopMode.all || (repeat == LoopMode.one && !automatic)) {
      if (queue.length == 1) {
        await PlayerService.seek(0);
        await PlayerService.play();
        position = Duration.zero;
        playing = true;
        notifyListeners();
        _sync();
      } else {
        index = 0;
        await _open();
      }
    } else if (automatic) {
      await PlayerService.pause();
      await PlayerService.seek(0);
      position = Duration.zero;
      playing = false;
      notifyListeners();
      _sync();
    }
  }

  Future<void> previous() async {
    if (!hasTrack) return;
    if (position > _restartThreshold) {
      await seekTo(Duration.zero);
      return;
    }
    if (hasPrevious) {
      index--;
      await _open();
    } else if (repeat == LoopMode.all && queue.length > 1) {
      index = queue.length - 1;
      await _open();
    } else {
      await seekTo(Duration.zero);
    }
  }

  Future<void> jumpTo(int target) async {
    if (target < 0 || target >= queue.length) return;
    index = target;
    await _open();
  }

  Future<void> seekTo(Duration target) async {
    if (!hasTrack) return;
    var clamped = target < Duration.zero ? Duration.zero : target;
    final max = Duration(milliseconds: durationMs);
    if (durationMs > 0 && clamped > max) clamped = max;
    position = clamped;
    notifyListeners();
    await PlayerService.seek(clamped.inMilliseconds);
    _sync();
  }

  void startScrub() => dragging = true;

  void previewScrub(Duration target) {
    position = target;
    notifyListeners();
  }

  Future<void> endScrub(Duration target) async {
    await seekTo(target);
    dragging = false;
  }

  Future<void> setSpeed(double value) async {
    speed = value;
    notifyListeners();
    await PlayerService.setSpeed(value);
    _sync();
  }

  void setSleepTimer(int minutes) {
    sleepAt = minutes == 0
        ? null
        : DateTime.now().add(Duration(minutes: minutes));
    sleepTotalSeconds = minutes * 60;
    notifyListeners();
  }

  void playNext(TrackItem item) {
    if (!hasTrack) {
      unawaited(playSingle(item));
      return;
    }
    final current = track!;
    queue.insert(index + 1, item);
    final at = _original.indexOf(current);
    _original.insert(at < 0 ? _original.length : at + 1, item);
    notifyListeners();
  }

  void enqueue(TrackItem item) {
    if (!hasTrack) {
      unawaited(playSingle(item));
      return;
    }
    queue.add(item);
    _original.add(item);
    notifyListeners();
  }

  void moveInQueue(int from, int to) {
    if (from < 0 || from >= queue.length || to < 0 || to >= queue.length) return;
    if (from == to) return;
    final item = queue.removeAt(from);
    queue.insert(to, item);
    if (index == from) {
      index = to;
    } else if (from < index && to >= index) {
      index--;
    } else if (from > index && to <= index) {
      index++;
    }
    if (!shuffle) _original = List<TrackItem>.of(queue);
    _persist();
    notifyListeners();
  }

  void removeAt(int target) {
    if (target < 0 || target >= queue.length || target == index) return;
    final removed = queue.removeAt(target);
    _original.remove(removed);
    if (target < index) index--;
    notifyListeners();
  }

  Future<void> stop() async {
    _generation++;
    _pendingOpen = false;
    _forgetQueue();
    _poller?.cancel();
    _poller = null;
    queue = <TrackItem>[];
    _original = <TrackItem>[];
    index = -1;
    playing = false;
    loading = false;
    failed = false;
    sleepAt = null;
    sleepTotalSeconds = 0;
    position = Duration.zero;
    if (!WindowService.playerOpen.value) {
      PlayerService.onCompleted = null;
      PlayerService.onError = null;
    }
    await PlayerService.close();
    await WindowService.setBackground(on: false);
    notifyListeners();
  }
}
