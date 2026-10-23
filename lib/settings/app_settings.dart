import 'package:flutter/material.dart';
import 'package:papuy/core/kv_store.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/settings/aspect_mode.dart';
import 'package:papuy/settings/float_shape.dart';
import 'package:papuy/settings/orientation_mode.dart';
import 'package:papuy/settings/loop_mode.dart';
import 'package:papuy/settings/music_sort.dart';
import 'package:papuy/settings/sort_key.dart';
import 'package:papuy/settings/subtitle_color.dart';
import 'package:papuy/theme/app_motion.dart';
import 'package:papuy/theme/catppuccin.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs) {
    _read();
  }

  static AppSettings load(KvStore store) => AppSettings._(store);

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static const _keys = <String>[
    'themeMode',
    'language',
    'showThumbnails',
    'showExtensions',
    'showHidden',
    'resume',
    'autoNext',
    'keepAwake',
    'background',
    'rememberSpeed',
    'autoFloat',
    'floatControls',
    'swipeBrightness',
    'swipeVolume',
    'swipeSeek',
    'longPressSpeed',
    'subtitles',
    'subtitleBox',
    'volumeBoost',
    'sortAsc',
    'groupFolders',
    'grid',
    'autoplay',
    'pauseNoisy',
    'skipSilence',
    'exactSeek',
    'showClock',
    'showRemaining',
    'checkUpdates',
    'speed',
    'hideDelay',
    'doubleTap',
    'subtitleSize',
    'subtitlePos',
    'audioLang',
    'subtitleLang',
    'sort',
    'aspect',
    'repeat',
    'orientation',
    'floatShape',
    'subtitleColor',
    'uiScale',
    'musicShuffle',
    'musicRepeat',
    'musicRestore',
    'musicVisualizer',
    'musicSort',
    'accent',
    'accentUpdatedAt',
    'syncAccent',
    'animations',
    'gridSize',
    'haptics',
    'quickPlay',
  ];

  final KvStore _prefs;

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = L10n.system;
  bool _showThumbnails = true;
  bool _showExtensions = true;
  bool _showHidden = false;
  bool _resume = true;
  bool _autoNext = true;
  bool _keepAwake = true;
  bool _background = false;
  bool _rememberSpeed = false;
  bool _autoFloat = true;
  bool _floatControls = true;
  bool _swipeBrightness = true;
  bool _swipeVolume = true;
  bool _swipeSeek = true;
  bool _longPressSpeed = true;
  bool _subtitles = true;
  bool _subtitleBox = false;
  bool _volumeBoost = false;
  bool _sortAsc = false;
  bool _groupFolders = true;
  bool _grid = false;
  bool _autoplay = true;
  bool _pauseNoisy = true;
  bool _skipSilence = false;
  bool _exactSeek = false;
  bool _showClock = false;
  bool _showRemaining = false;
  bool _checkUpdates = true;
  bool _musicShuffle = false;
  bool _musicRestore = true;
  bool _musicVisualizer = true;
  String _accent = CatppuccinPalette.defaultAccent;
  int _appearanceUpdatedAt = 0;
  bool _syncAppearance = true;
  bool _animations = true;
  int _gridSize = 240;
  bool _haptics = true;
  bool _quickPlay = true;
  MusicSort _musicSort = MusicSort.title;
  int _speed = 100;
  int _hideDelay = 3;
  int _doubleTap = 10;
  int _subtitleSize = 20;
  int _subtitlePos = 85;
  int _uiScale = 90;
  String _audioLang = 'auto';
  String _subtitleLang = 'auto';
  SortKey _sort = SortKey.date;
  AspectMode _aspect = AspectMode.fit;
  LoopMode _repeat = LoopMode.off;
  LoopMode _musicRepeat = LoopMode.all;
  OrientationMode _orientation = OrientationMode.auto;
  FloatShape _floatShape = FloatShape.video;
  SubtitleColor _subtitleColor = SubtitleColor.white;

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get showThumbnails => _showThumbnails;
  bool get showExtensions => _showExtensions;
  bool get showHidden => _showHidden;
  bool get resume => _resume;
  bool get autoNext => _autoNext;
  bool get keepAwake => _keepAwake;
  bool get background => _background;
  bool get rememberSpeed => _rememberSpeed;
  bool get autoFloat => _autoFloat;
  bool get floatControls => _floatControls;
  bool get swipeBrightness => _swipeBrightness;
  bool get swipeVolume => _swipeVolume;
  bool get swipeSeek => _swipeSeek;
  bool get longPressSpeed => _longPressSpeed;
  bool get subtitles => _subtitles;
  bool get subtitleBox => _subtitleBox;
  bool get volumeBoost => _volumeBoost;
  bool get sortAsc => _sortAsc;
  bool get groupFolders => _groupFolders;
  bool get grid => _grid;
  bool get autoplay => _autoplay;
  bool get pauseNoisy => _pauseNoisy;
  bool get skipSilence => _skipSilence;
  bool get exactSeek => _exactSeek;
  bool get showClock => _showClock;
  bool get showRemaining => _showRemaining;
  bool get checkUpdates => _checkUpdates;
  bool get backgroundAsked => _prefs.getBool('backgroundAsked') ?? false;
  int get speed => _speed;
  bool get musicShuffle => _musicShuffle;
  bool get musicRestore => _musicRestore;
  bool get musicVisualizer => _musicVisualizer;
  String get accent => _accent;
  int get appearanceUpdatedAt => _appearanceUpdatedAt;
  bool get syncAppearance => _syncAppearance;
  bool get animations => _animations;
  int get gridSize => _gridSize;
  bool get haptics => _haptics;
  bool get quickPlay => _quickPlay;
  MusicSort get musicSort => _musicSort;
  LoopMode get musicRepeat => _musicRepeat;
  int get uiScale => _uiScale;
  int get hideDelay => _hideDelay;
  int get doubleTap => _doubleTap;
  int get subtitleSize => _subtitleSize;
  int get subtitlePos => _subtitlePos;
  String get audioLang => _audioLang;
  String get subtitleLang => _subtitleLang;
  SortKey get sort => _sort;
  AspectMode get aspect => _aspect;
  LoopMode get repeat => _repeat;
  OrientationMode get orientation => _orientation;
  FloatShape get floatShape => _floatShape;
  SubtitleColor get subtitleColor => _subtitleColor;

  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _stamp();
    _set(() => _themeMode = value, 'themeMode', value.name);
  }

  set language(String value) {
    _language = value;
    L10n.code = L10n.resolve(value);
    _prefs.setString('language', value);
    notifyListeners();
  }

  set showThumbnails(bool value) =>
      _set(() => _showThumbnails = value, 'showThumbnails', value);

  set showExtensions(bool value) =>
      _set(() => _showExtensions = value, 'showExtensions', value);

  set showHidden(bool value) =>
      _set(() => _showHidden = value, 'showHidden', value);

  set resume(bool value) =>
      _set(() => _resume = value, 'resume', value);

  set autoNext(bool value) =>
      _set(() => _autoNext = value, 'autoNext', value);

  set keepAwake(bool value) =>
      _set(() => _keepAwake = value, 'keepAwake', value);

  set background(bool value) =>
      _set(() => _background = value, 'background', value);

  set rememberSpeed(bool value) =>
      _set(() => _rememberSpeed = value, 'rememberSpeed', value);

  set autoFloat(bool value) =>
      _set(() => _autoFloat = value, 'autoFloat', value);

  set floatControls(bool value) =>
      _set(() => _floatControls = value, 'floatControls', value);

  set swipeBrightness(bool value) =>
      _set(() => _swipeBrightness = value, 'swipeBrightness', value);

  set swipeVolume(bool value) =>
      _set(() => _swipeVolume = value, 'swipeVolume', value);

  set swipeSeek(bool value) =>
      _set(() => _swipeSeek = value, 'swipeSeek', value);

  set longPressSpeed(bool value) =>
      _set(() => _longPressSpeed = value, 'longPressSpeed', value);

  set subtitles(bool value) =>
      _set(() => _subtitles = value, 'subtitles', value);

  set subtitleBox(bool value) =>
      _set(() => _subtitleBox = value, 'subtitleBox', value);

  set volumeBoost(bool value) =>
      _set(() => _volumeBoost = value, 'volumeBoost', value);

  set sortAsc(bool value) =>
      _set(() => _sortAsc = value, 'sortAsc', value);

  set groupFolders(bool value) =>
      _set(() => _groupFolders = value, 'groupFolders', value);

  set grid(bool value) =>
      _set(() => _grid = value, 'grid', value);

  set autoplay(bool value) =>
      _set(() => _autoplay = value, 'autoplay', value);

  set pauseNoisy(bool value) =>
      _set(() => _pauseNoisy = value, 'pauseNoisy', value);

  set skipSilence(bool value) =>
      _set(() => _skipSilence = value, 'skipSilence', value);

  set exactSeek(bool value) =>
      _set(() => _exactSeek = value, 'exactSeek', value);

  set showClock(bool value) =>
      _set(() => _showClock = value, 'showClock', value);

  set showRemaining(bool value) =>
      _set(() => _showRemaining = value, 'showRemaining', value);

  set backgroundAsked(bool value) => _prefs.setBool('backgroundAsked', value);

  set checkUpdates(bool value) =>
      _set(() => _checkUpdates = value, 'checkUpdates', value);

  set speed(int value) =>
      _set(() => _speed = value, 'speed', value);

  set accent(String value) {
    if (value == _accent && _appearanceUpdatedAt != 0) return;
    _stamp();
    _set(() => _accent = value, 'accent', value);
  }

  set syncAppearance(bool value) =>
      _set(() => _syncAppearance = value, 'syncAccent', value);

  void _stamp() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _appearanceUpdatedAt =
        now > _appearanceUpdatedAt ? now : _appearanceUpdatedAt + 1;
    _prefs.setInt('accentUpdatedAt', _appearanceUpdatedAt);
  }

  void adoptAppearance(String accent, String? mode, int updatedAt) {
    if (!CatppuccinPalette.accents.contains(accent)) return;
    if (updatedAt <= _appearanceUpdatedAt) return;
    _accent = accent;
    if (mode != null) _themeMode = _byName(ThemeMode.values, mode, _themeMode);
    _appearanceUpdatedAt = updatedAt;
    _prefs.setString('accent', accent);
    _prefs.setString('themeMode', _themeMode.name);
    _prefs.setInt('accentUpdatedAt', updatedAt);
    notifyListeners();
  }

  Future<void> flush() => _prefs.flush();

  set animations(bool value) => _set(() {
        _animations = value;
        AppMotion.enabled = value;
      }, 'animations', value);

  set gridSize(int value) => _set(() => _gridSize = value, 'gridSize', value);

  set haptics(bool value) => _set(() => _haptics = value, 'haptics', value);

  set quickPlay(bool value) =>
      _set(() => _quickPlay = value, 'quickPlay', value);

  set musicVisualizer(bool value) =>
      _set(() => _musicVisualizer = value, 'musicVisualizer', value);

  set musicRestore(bool value) =>
      _set(() => _musicRestore = value, 'musicRestore', value);

  set musicSort(MusicSort value) =>
      _set(() => _musicSort = value, 'musicSort', value.name);

  set musicShuffle(bool value) =>
      _set(() => _musicShuffle = value, 'musicShuffle', value, notify: false);

  set musicRepeat(LoopMode value) =>
      _set(() => _musicRepeat = value, 'musicRepeat', value.name, notify: false);

  set uiScale(int value) => _set(() => _uiScale = value, 'uiScale', value);
  set hideDelay(int value) =>
      _set(() => _hideDelay = value, 'hideDelay', value);

  set doubleTap(int value) =>
      _set(() => _doubleTap = value, 'doubleTap', value);

  set subtitleSize(int value) =>
      _set(() => _subtitleSize = value, 'subtitleSize', value);

  set subtitlePos(int value) =>
      _set(() => _subtitlePos = value, 'subtitlePos', value);

  set audioLang(String value) =>
      _set(() => _audioLang = value, 'audioLang', value);

  set subtitleLang(String value) =>
      _set(() => _subtitleLang = value, 'subtitleLang', value);

  set sort(SortKey value) =>
      _set(() => _sort = value, 'sort', value.name);

  set aspect(AspectMode value) =>
      _set(() => _aspect = value, 'aspect', value.name);

  set repeat(LoopMode value) =>
      _set(() => _repeat = value, 'repeat', value.name);

  set orientation(OrientationMode value) =>
      _set(() => _orientation = value, 'orientation', value.name);

  set floatShape(FloatShape value) =>
      _set(() => _floatShape = value, 'floatShape', value.name);

  set subtitleColor(SubtitleColor value) =>
      _set(() => _subtitleColor = value, 'subtitleColor', value.name);

  void reset() {
    for (final key in _keys) {
      _prefs.remove(key);
    }
    _read();
    notifyListeners();
  }

  void _read() {
    _themeMode = _byName(
      ThemeMode.values,
      _prefs.getString('themeMode'),
      ThemeMode.dark,
    );
    _language = _prefs.getString('language') ?? L10n.system;
    L10n.code = L10n.resolve(_language);
    _showThumbnails = _prefs.getBool('showThumbnails') ?? true;
    _showExtensions = _prefs.getBool('showExtensions') ?? true;
    _showHidden = _prefs.getBool('showHidden') ?? false;
    _resume = _prefs.getBool('resume') ?? true;
    _autoNext = _prefs.getBool('autoNext') ?? true;
    _keepAwake = _prefs.getBool('keepAwake') ?? true;
    _background = _prefs.getBool('background') ?? false;
    _rememberSpeed = _prefs.getBool('rememberSpeed') ?? false;
    _autoFloat = _prefs.getBool('autoFloat') ?? true;
    _floatControls = _prefs.getBool('floatControls') ?? true;
    _swipeBrightness = _prefs.getBool('swipeBrightness') ?? true;
    _swipeVolume = _prefs.getBool('swipeVolume') ?? true;
    _swipeSeek = _prefs.getBool('swipeSeek') ?? true;
    _longPressSpeed = _prefs.getBool('longPressSpeed') ?? true;
    _subtitles = _prefs.getBool('subtitles') ?? true;
    _subtitleBox = _prefs.getBool('subtitleBox') ?? false;
    _volumeBoost = _prefs.getBool('volumeBoost') ?? false;
    _sortAsc = _prefs.getBool('sortAsc') ?? false;
    _groupFolders = _prefs.getBool('groupFolders') ?? true;
    _grid = _prefs.getBool('grid') ?? false;
    _autoplay = _prefs.getBool('autoplay') ?? true;
    _pauseNoisy = _prefs.getBool('pauseNoisy') ?? true;
    _skipSilence = _prefs.getBool('skipSilence') ?? false;
    _exactSeek = _prefs.getBool('exactSeek') ?? false;
    _showClock = _prefs.getBool('showClock') ?? false;
    _showRemaining = _prefs.getBool('showRemaining') ?? false;
    _checkUpdates = _prefs.getBool('checkUpdates') ?? true;
    _speed = _prefs.getInt('speed') ?? 100;
    _musicShuffle = _prefs.getBool('musicShuffle') ?? false;
    _musicRestore = _prefs.getBool('musicRestore') ?? true;
    _musicVisualizer = _prefs.getBool('musicVisualizer') ?? true;
    final accent = _prefs.getString('accent');
    _accent = accent != null && CatppuccinPalette.accents.contains(accent)
        ? accent
        : CatppuccinPalette.defaultAccent;
    _appearanceUpdatedAt = _prefs.getInt('accentUpdatedAt') ?? 0;
    _syncAppearance = _prefs.getBool('syncAccent') ?? true;
    _animations = _prefs.getBool('animations') ?? true;
    AppMotion.enabled = _animations;
    _gridSize = _prefs.getInt('gridSize') ?? 240;
    _haptics = _prefs.getBool('haptics') ?? true;
    _quickPlay = _prefs.getBool('quickPlay') ?? true;
    _musicSort = _byName(MusicSort.values, _prefs.getString('musicSort'), MusicSort.title);
    _musicRepeat = _byName(LoopMode.values, _prefs.getString('musicRepeat'), LoopMode.all);
    _uiScale = _prefs.getInt('uiScale') ?? 90;
    _hideDelay = _prefs.getInt('hideDelay') ?? 3;
    _doubleTap = _prefs.getInt('doubleTap') ?? 10;
    _subtitleSize = _prefs.getInt('subtitleSize') ?? 20;
    _subtitlePos = _prefs.getInt('subtitlePos') ?? 85;
    _audioLang = _prefs.getString('audioLang') ?? 'auto';
    _subtitleLang = _prefs.getString('subtitleLang') ?? 'auto';
    _sort = _byName(SortKey.values, _prefs.getString('sort'), SortKey.date);
    _aspect = _byName(AspectMode.values, _prefs.getString('aspect'), AspectMode.fit);
    _repeat = _byName(LoopMode.values, _prefs.getString('repeat'), LoopMode.off);
    _orientation = _byName(OrientationMode.values, _prefs.getString('orientation'), OrientationMode.auto);
    _floatShape = _byName(FloatShape.values, _prefs.getString('floatShape'), FloatShape.video);
    _subtitleColor = _byName(SubtitleColor.values, _prefs.getString('subtitleColor'), SubtitleColor.white);
  }

  void _set(
    VoidCallback change,
    String key,
    Object value, {
    bool notify = true,
  }) {
    change();
    switch (value) {
      case final bool v:
        _prefs.setBool(key, v);
      case final int v:
        _prefs.setInt(key, v);
      case final String v:
        _prefs.setString(key, v);
    }
    if (notify) notifyListeners();
  }
}
