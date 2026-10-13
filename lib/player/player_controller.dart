import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:papuy/app_info.dart';
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/platform/player_service.dart';
import 'package:papuy/platform/window_service.dart';
import 'package:papuy/player/player_info.dart';
import 'package:papuy/player/subtitle_cue.dart';
import 'package:papuy/player/track_option.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/settings/aspect_mode.dart';
import 'package:papuy/settings/float_shape.dart';
import 'package:papuy/settings/orientation_mode.dart';
import 'package:papuy/settings/loop_mode.dart';

class PlayerController extends ChangeNotifier with WidgetsBindingObserver {
  PlayerController({
    required this.settings,
    required this.library,
    required this.playlist,
    required this.index,
    this.quick = false,
  })  : aspect = settings.aspect,
        repeat = settings.repeat,
        orientation = settings.orientation,
        subtitlesVisible = settings.subtitles;

  static const double _levelStep = 260;
  static const double _scrubFactor = 0.4;

  final AppSettings settings;
  final LibraryController library;
  final List<VideoItem> playlist;
  final bool quick;

  int index;
  PlayerInfo? info;
  List<TrackOption> tracks = <TrackOption>[];
  int videoWidth = 0;
  int videoHeight = 0;
  double pixelRatio = 1;
  int rotation = 0;
  int durationMs = 0;
  bool loading = true;
  bool failed = false;
  bool buffering = false;

  Duration position = Duration.zero;
  bool playing = false;
  bool controlsVisible = true;
  bool locked = false;
  bool muted = false;
  bool dragging = false;
  double speed = 1.0;
  AspectMode aspect;
  LoopMode repeat;
  OrientationMode orientation;
  bool videoAuto = true;

  int? markA;
  int? markB;
  DateTime? sleepAt;

  List<SubtitleCue> cues = <SubtitleCue>[];
  String? cueText;
  int subtitleDelayMs = 0;
  bool subtitlesVisible;

  double brightness = 0.5;
  double volume = 0.5;
  String? toast;

  String _embeddedCue = '';
  bool _polling = false;
  bool _disposed = false;
  int _ticks = 0;
  bool _dragIsVolume = false;
  double _scrub = 0;
  double _tapX = 0;
  double? _speedBeforeHold;

  Timer? _poller;
  Timer? _hideTimer;
  Timer? _toastTimer;

  VideoItem get video => playlist[index];
  bool get hasPrevious => index > 0;
  bool get hasNext => index < playlist.length - 1;
  double get _defaultSpeed => settings.speed / 100;

  String get speedLabel {
    final text = speed.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  bool get _swapped => rotation % 180 != 0;
  int get displayWidth => _swapped ? videoHeight : videoWidth;
  int get displayHeight => _swapped ? videoWidth : videoHeight;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void start() {
    WidgetsBinding.instance.addObserver(this);
    WindowService.playerOpen.value = true;
    if (!quick) {
      _applyOrientation();
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }
    PlayerService.onCompleted = _onCompleted;
    PlayerService.onSize = _onSize;
    PlayerService.onTracks = _onTracks;
    PlayerService.onCue = (text) => _embeddedCue = text;
    PlayerService.onError = (code) {
      debugPrint('papuy player error: $code');
      failed = true;
      loading = false;
      notifyListeners();
    };
    unawaited(WindowService.keepAwake(on: settings.keepAwake));
    unawaited(_readLevels());
    _poller = Timer.periodic(const Duration(milliseconds: 250), (_) => _poll());
    unawaited(open());
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    _hideTimer?.cancel();
    _toastTimer?.cancel();
    _persist();
    PlayerService.onCompleted = null;
    PlayerService.onSize = null;
    PlayerService.onTracks = null;
    PlayerService.onCue = null;
    PlayerService.onError = null;
    WindowService.playerOpen.value = false;
    unawaited(PlayerService.close());
    unawaited(WindowService.setBackground(on: false));
    unawaited(WindowService.setBrightness(-1));
    unawaited(WindowService.keepAwake(on: false));
    if (!quick) {
      unawaited(WindowService.setAutoPip(on: false, width: 16, height: 9));
      unawaited(
        SystemChrome.setPreferredOrientations(DeviceOrientation.values),
      );
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(WindowService.setBackground(on: false));
      return;
    }
    if (state != AppLifecycleState.paused) return;
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (_disposed || WindowService.inPip.value || !playing) return;
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        return;
      }
      if (settings.background) {
        unawaited(
          WindowService.setBackground(
            on: true,
            title: library.title(video),
            playing: true,
          ),
        );
      } else {
        unawaited(PlayerService.pause());
        playing = false;
        notifyListeners();
      }
    });
  }

  void _onSize(int width, int height, double ratio, int turns) {
    videoWidth = width;
    videoHeight = height;
    pixelRatio = ratio;
    rotation = turns;
    notifyListeners();
    _applyOrientation();
  }

  void _onTracks(List<TrackOption> list) {
    tracks = list;
    notifyListeners();
  }

  void _applyOrientation() {
    if (quick) return;
    final List<DeviceOrientation> list;
    switch (orientation) {
      case OrientationMode.landscape:
        list = const <DeviceOrientation>[
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ];
      case OrientationMode.portrait:
        list = const <DeviceOrientation>[DeviceOrientation.portraitUp];
      case OrientationMode.sensor:
        list = DeviceOrientation.values;
      case OrientationMode.auto:
        var wide = displayWidth;
        var tall = displayHeight;
        if (wide <= 0 || tall <= 0) {
          wide = video.width;
          tall = video.height;
        }
        if (wide <= 0 || tall <= 0) return;
        list = tall > wide
            ? const <DeviceOrientation>[DeviceOrientation.portraitUp]
            : const <DeviceOrientation>[
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ];
    }
    unawaited(SystemChrome.setPreferredOrientations(list));
  }

  void setOrientation(OrientationMode mode) {
    orientation = mode;
    _applyOrientation();
    notifyListeners();
  }

  void cycleOrientation() {
    setOrientation(orientation.next);
    showToast(orientation.label);
    armHide();
  }

  Future<void> _readLevels() async {
    brightness = await WindowService.getBrightness();
    volume = await WindowService.getVolume();
    notifyListeners();
  }

  Future<void> open() async {
    loading = true;
    failed = false;
    info = null;
    tracks = <TrackOption>[];
    cues = <SubtitleCue>[];
    cueText = null;
    _embeddedCue = '';
    subtitleDelayMs = 0;
    markA = null;
    markB = null;
    videoAuto = true;
    notifyListeners();
    final item = video;
    final startMs = settings.resume ? library.position(item) : 0;
    final startSpeed = settings.rememberSpeed
        ? (library.savedSpeed(item) ?? _defaultSpeed)
        : _defaultSpeed;
    final autoplay = settings.autoplay;
    try {
      final opened = await PlayerService.open(
        uri: item.uri,
        startMs: startMs,
        speed: startSpeed,
        boost: settings.volumeBoost,
        play: autoplay,
        audioLang: settings.audioLang,
        subtitleLang: settings.subtitleLang,
        skipSilence: settings.skipSilence,
        exactSeek: settings.exactSeek,
        pauseNoisy: settings.pauseNoisy,
      );
      if (_disposed) {
        unawaited(PlayerService.close());
        return;
      }
      if (muted) unawaited(PlayerService.mute(on: true));
      library.markPlayed(item);
      info = opened;
      tracks = opened.tracks;
      videoWidth = opened.width;
      videoHeight = opened.height;
      pixelRatio = opened.ratio;
      rotation = opened.rotation;
      durationMs = opened.durationMs;
      speed = startSpeed;
      position = Duration(milliseconds: startMs);
      playing = autoplay;
      loading = false;
      controlsVisible = true;
      notifyListeners();
      _applyOrientation();
      syncAutoPip();
      armHide();
    } on Object {
      loading = false;
      failed = true;
      notifyListeners();
    }
  }

  Future<void> _poll() async {
    if (info == null || _disposed || _polling) return;
    _polling = true;
    final snapshot = await PlayerService.snapshot();
    _polling = false;
    if (snapshot == null || _disposed) return;
    final a = markA;
    final b = markB;
    if (a != null && b != null && snapshot.positionMs >= b) {
      unawaited(PlayerService.seek(a));
    }
    var isPlaying = snapshot.playing;
    final sleep = sleepAt;
    if (sleep != null && DateTime.now().isAfter(sleep)) {
      sleepAt = null;
      unawaited(PlayerService.pause());
      isPlaying = false;
      showToast('Sleep timer');
    }
    final current = Duration(milliseconds: snapshot.positionMs);
    String? cue;
    if (subtitlesVisible) {
      if (cues.isNotEmpty) {
        final shifted = current - Duration(milliseconds: subtitleDelayMs);
        for (final item in cues) {
          if (shifted >= item.start && shifted < item.end) {
            cue = item.text;
            break;
          }
        }
      } else if (_embeddedCue.isNotEmpty) {
        cue = _embeddedCue;
      }
    }
    if (!dragging) position = current;
    playing = isPlaying;
    buffering = snapshot.buffering;
    if (snapshot.durationMs > 0) durationMs = snapshot.durationMs;
    cueText = cue;
    notifyListeners();
    _ticks++;
    if (_ticks % 20 == 0 && snapshot.playing) _persist();
  }

  void _persist() {
    if (info == null) return;
    final ms = position.inMilliseconds;
    final nearEnd = durationMs > 0 && ms >= durationMs - 3000;
    library.savePosition(video, nearEnd ? 0 : ms);
  }

  void _onCompleted() {
    if (_disposed) return;
    library.savePosition(video, 0);
    if (repeat == LoopMode.one) {
      unawaited(PlayerService.seek(0));
      unawaited(PlayerService.play());
    } else if (hasNext && (repeat == LoopMode.all || settings.autoNext)) {
      unawaited(go(index + 1));
    } else if (repeat == LoopMode.all && playlist.length > 1) {
      unawaited(go(0));
    } else if (repeat == LoopMode.all) {
      unawaited(PlayerService.seek(0));
      unawaited(PlayerService.play());
    } else {
      playing = false;
      controlsVisible = true;
      notifyListeners();
    }
  }

  Future<void> go(int target) async {
    if (target < 0 || target >= playlist.length) return;
    _persist();
    index = target;
    notifyListeners();
    await open();
  }

  void armHide() {
    _hideTimer?.cancel();
    if (!playing) return;
    _hideTimer = Timer(Duration(seconds: settings.hideDelay), () {
      controlsVisible = false;
      notifyListeners();
    });
  }

  void cancelHide() => _hideTimer?.cancel();

  void toggleControls() {
    controlsVisible = !controlsVisible;
    notifyListeners();
    if (controlsVisible) armHide();
  }

  void showToast(String text) {
    _toastTimer?.cancel();
    toast = text;
    notifyListeners();
    _toastTimer = Timer(const Duration(milliseconds: 900), () {
      toast = null;
      notifyListeners();
    });
  }

  List<int> pipSize() {
    switch (settings.floatShape) {
      case FloatShape.wide:
        return <int>[16, 9];
      case FloatShape.square:
        return <int>[1, 1];
      case FloatShape.video:
        final width = displayWidth > 0 ? displayWidth : 16;
        final height = displayHeight > 0 ? displayHeight : 9;
        if (width / height > 2.39) return <int>[239, 100];
        if (height / width > 2.39) return <int>[100, 239];
        return <int>[width, height];
    }
  }

  void syncAutoPip() {
    if (quick) return;
    final size = pipSize();
    unawaited(
      WindowService.setAutoPip(
        on: settings.autoFloat && playing,
        width: size[0],
        height: size[1],
        buttons: settings.floatControls,
      ),
    );
  }

  void enterPip() {
    final size = pipSize();
    unawaited(
      WindowService.enterPip(
        size[0],
        size[1],
        buttons: settings.floatControls,
      ),
    );
  }

  Future<void> togglePlay() async {
    if (info == null) return;
    if (playing) {
      await PlayerService.pause();
    } else {
      if (durationMs > 0 && position.inMilliseconds >= durationMs - 500) {
        await PlayerService.seek(0);
        position = Duration.zero;
      }
      await PlayerService.play();
    }
    playing = !playing;
    notifyListeners();
    syncAutoPip();
    armHide();
  }

  void seekTo(Duration target) {
    if (info == null) return;
    var clamped = target < Duration.zero ? Duration.zero : target;
    final max = Duration(milliseconds: durationMs);
    if (durationMs > 0 && clamped > max) clamped = max;
    unawaited(PlayerService.seek(clamped.inMilliseconds));
    position = clamped;
    notifyListeners();
  }

  void seekBy(int seconds) {
    seekTo(position + Duration(seconds: seconds));
    showToast(seconds > 0 ? '+${seconds}s' : '${seconds}s');
  }

  void startScrub() => dragging = true;

  void previewScrub(Duration target) {
    position = target;
    notifyListeners();
  }

  void endScrub(Duration target) {
    dragging = false;
    seekTo(target);
    armHide();
  }

  void applySpeed(double value) {
    speed = value;
    unawaited(PlayerService.setSpeed(value));
    notifyListeners();
  }

  void chooseSpeed(double value) {
    applySpeed(value);
    if (settings.rememberSpeed) library.saveSpeed(video, value);
  }

  void setAspect(AspectMode mode) {
    aspect = mode;
    notifyListeners();
  }

  void cycleAspect() {
    setAspect(aspect.next);
    showToast(aspect.label);
    armHide();
  }

  void cycleRepeat() {
    repeat = repeat.next;
    notifyListeners();
    showToast(repeat.toast);
    armHide();
  }

  void toggleMute() {
    muted = !muted;
    unawaited(PlayerService.mute(on: muted));
    notifyListeners();
    showToast(muted ? 'Muted' : 'Sound on');
  }

  void toggleLock() {
    locked = !locked;
    controlsVisible = true;
    notifyListeners();
    showToast(locked ? 'Locked' : 'Unlocked');
    armHide();
  }

  void markLoop() {
    final current = position.inMilliseconds;
    final a = markA;
    if (a == null) {
      markA = current;
      showToast('A  ${formatDuration(position)}');
    } else if (markB == null && current > a) {
      markB = current;
      showToast('B  ${formatDuration(position)}');
    } else {
      markA = null;
      markB = null;
      showToast('A–B cleared');
    }
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    sleepAt = minutes == 0
        ? null
        : DateTime.now().add(Duration(minutes: minutes));
    notifyListeners();
    showToast(minutes == 0 ? 'Timer off' : 'Pause in $minutes min');
  }

  Future<void> screenshot() async {
    final saved = await MediaService.screenshot(
      video.uri,
      position.inMilliseconds,
    );
    showToast(saved ? 'Saved to Pictures/${AppInfo.name}' : "Can't capture");
  }

  void onTapDown(double x) => _tapX = x;

  void onDoubleTap(double width) {
    if (_tapX < width * 0.35) {
      seekBy(-settings.doubleTap);
    } else if (_tapX > width * 0.65) {
      seekBy(settings.doubleTap);
    } else {
      unawaited(togglePlay());
    }
  }

  void onVerticalDragStart(double x, double width) {
    _dragIsVolume = x > width / 2;
  }

  void onVerticalDragUpdate(double deltaY) {
    final delta = -deltaY / _levelStep;
    if (_dragIsVolume) {
      if (!settings.swipeVolume) return;
      volume = (volume + delta).clamp(0.0, 1.0).toDouble();
      unawaited(WindowService.setVolume(volume));
      showToast('Volume ${(volume * 100).round()}%');
    } else {
      if (!settings.swipeBrightness) return;
      brightness = (brightness + delta).clamp(0.02, 1.0).toDouble();
      unawaited(WindowService.setBrightness(brightness));
      showToast('Brightness ${(brightness * 100).round()}%');
    }
  }

  void onHorizontalDragStart() => _scrub = 0;

  void onHorizontalDragUpdate(double deltaX) {
    if (!settings.swipeSeek) return;
    _scrub += deltaX * _scrubFactor;
    final seconds = _scrub.round();
    showToast('${seconds >= 0 ? '+' : '−'}${seconds.abs()}s');
  }

  void onHorizontalDragEnd() {
    if (settings.swipeSeek && _scrub.abs() >= 1) {
      seekTo(position + Duration(seconds: _scrub.round()));
    }
    _scrub = 0;
  }

  void onHoldStart() {
    if (settings.longPressSpeed && playing) {
      _speedBeforeHold = speed;
      applySpeed(2.0);
      showToast('2×');
    }
  }

  void onHoldEnd() {
    final back = _speedBeforeHold;
    if (back != null) {
      applySpeed(back);
      _speedBeforeHold = null;
    }
  }

  void selectTrack(TrackOption track) {
    unawaited(PlayerService.selectTrack(track.type, track.group, track.index));
    if (track.type == 'text') {
      subtitlesVisible = true;
      cues = <SubtitleCue>[];
    } else if (track.type == 'video') {
      videoAuto = false;
    }
    notifyListeners();
  }

  void disableSubtitleTrack() {
    unawaited(PlayerService.selectTrack('text', -1, -1));
    _embeddedCue = '';
    notifyListeners();
  }

  void selectAutoQuality() {
    unawaited(PlayerService.selectTrack('video', -1, -1));
    videoAuto = true;
    notifyListeners();
  }

  void setSubtitlesVisible({required bool visible}) {
    subtitlesVisible = visible;
    notifyListeners();
  }

  void shiftSubtitles(int deltaMs) {
    subtitleDelayMs += deltaMs;
    notifyListeners();
  }

  Future<void> loadSubtitleFile() async {
    final raw = await MediaService.pickSubtitle();
    if (raw == null || _disposed) return;
    cues = parseSrt(raw);
    subtitlesVisible = true;
    notifyListeners();
  }
}
