import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/notification_service.dart';
import 'package:papuy/theme/catppuccin.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/settings/aspect_mode.dart';
import 'package:papuy/settings/float_shape.dart';
import 'package:papuy/settings/orientation_mode.dart';
import 'package:papuy/settings/loop_mode.dart';
import 'package:papuy/settings/sort_key.dart';
import 'package:papuy/settings/subtitle_color.dart';
import 'package:papuy/theme/app_motion.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/language_sheet.dart';
import 'package:papuy/ui/widgets/choice_tile.dart';
import 'package:papuy/ui/widgets/page_frame.dart';
import 'package:papuy/ui/widgets/settings_section.dart';

const Map<int, String> _speeds = <int, String>{
  50: '0.5×',
  75: '0.75×',
  100: '1.0×',
  125: '1.25×',
  150: '1.5×',
  200: '2.0×',
};

const Map<int, String> _hideDelays = <int, String>{
  2: '2 seconds',
  3: '3 seconds',
  5: '5 seconds',
  10: '10 seconds',
};

const Map<int, String> _doubleTaps = <int, String>{
  5: '5 seconds',
  10: '10 seconds',
  15: '15 seconds',
  30: '30 seconds',
};

const Map<int, String> _subtitlePositions = <int, String>{
  60: 'High',
  75: 'Middle',
  85: 'Low',
  93: 'Bottom',
};

const Map<String, String> _subtitleLanguages = <String, String>{
  'auto': 'Automatic',
  'off': 'Off',
  'en': 'English',
  'fa': 'Persian',
  'ar': 'Arabic',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'ru': 'Russian',
  'tr': 'Turkish',
};

const Map<String, String> _audioLanguages = <String, String>{
  'auto': 'Automatic',
  'en': 'English',
  'fa': 'Persian',
  'ar': 'Arabic',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'ru': 'Russian',
  'tr': 'Turkish',
  'ja': 'Japanese',
};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.library,
    super.key,
  });

  final AppSettings settings;
  final LibraryController library;

  Widget _switch(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String done,
    VoidCallback run,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        run();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(done)));
      },
    );
  }

  Widget _appearance() {
    return SettingsSection(
      title: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SegmentedButton<ThemeMode>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
              ButtonSegment(value: ThemeMode.light, label: Text('Latte')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Mocha')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                settings.themeMode = selection.first,
          ),
        ),
        _AccentTile(settings: settings),
        _ScaleTile(settings: settings),
        _GridTile(settings: settings),
        _switch(
          Icons.animation_rounded,
          'Animations',
          settings.animations,
          (value) => settings.animations = value,
        ),
        _switch(
          Icons.vibration_rounded,
          'Haptic feedback',
          settings.haptics,
          (value) => settings.haptics = value,
        ),
      ],
    );
  }

  Widget _defaults(BuildContext context) {
    return SettingsSection(
      title: 'Quick play',
      children: [
        _switch(
          Icons.picture_in_picture_rounded,
          'Quick play window',
          settings.quickPlay,
          (value) => settings.quickPlay = value,
        ),
      ],
    );
  }

  Widget _language(BuildContext context) {
    return SettingsSection(
      title: 'Language',
      children: [
        ListTile(
          title: const Text('Language'),
          subtitle: Text(_languageName(settings.language)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _pickLanguage(context),
        ),
      ],
    );
  }

  Widget _library() {
    return SettingsSection(
      title: 'Library',
      children: [
        ChoiceTile<SortKey>(
          icon: Icons.sort_rounded,
          title: 'Sort videos by',
          value: settings.sort,
          options: <SortKey, String>{
            for (final key in SortKey.values) key: key.label,
          },
          onChanged: (value) => settings.sort = value,
        ),
        _switch(
          Icons.swap_vert_rounded,
          'Reverse order',
          settings.sortAsc,
          (value) => settings.sortAsc = value,
        ),
        _switch(
          Icons.folder_open_rounded,
          'Group by folder',
          settings.groupFolders,
          (value) => settings.groupFolders = value,
        ),
        _switch(
          Icons.grid_view_rounded,
          'Grid view',
          settings.grid,
          (value) => settings.grid = value,
        ),
        _switch(
          Icons.image_outlined,
          'Show thumbnails',
          settings.showThumbnails,
          (value) => settings.showThumbnails = value,
        ),
        _switch(
          Icons.title_rounded,
          'Show file extensions',
          settings.showExtensions,
          (value) => settings.showExtensions = value,
        ),
        _switch(
          Icons.visibility_off_outlined,
          'Show hidden folders',
          settings.showHidden,
          (value) => settings.showHidden = value,
        ),
      ],
    );
  }

  Widget _music() {
    return SettingsSection(
      title: 'Music',
      children: [
        _switch(
          Icons.queue_music_rounded,
          'Remember last queue',
          settings.musicRestore,
          (value) => settings.musicRestore = value,
        ),
        _switch(
          Icons.graphic_eq_rounded,
          'Show visualizer',
          settings.musicVisualizer,
          (value) => settings.musicVisualizer = value,
        ),
      ],
    );
  }

  Widget _playback() {
    return SettingsSection(
      title: 'Playback',
      children: [
        _switch(
          Icons.history_rounded,
          'Resume playback',
          settings.resume,
          (value) => settings.resume = value,
        ),
        _switch(
          Icons.skip_next_rounded,
          'Play next automatically',
          settings.autoNext,
          (value) => settings.autoNext = value,
        ),
        _switch(
          Icons.lightbulb_outline_rounded,
          'Keep screen on',
          settings.keepAwake,
          (value) => settings.keepAwake = value,
        ),
        _switch(
          Icons.headphones_rounded,
          'Keep playing in background',
          settings.background,
          (value) {
            settings.background = value;
            if (value) NotificationService.requestPermission();
          },
        ),
        _switch(
          Icons.play_circle_outline_rounded,
          'Start playing automatically',
          settings.autoplay,
          (value) => settings.autoplay = value,
        ),
        _switch(
          Icons.headset_off_rounded,
          'Pause when headphones unplug',
          settings.pauseNoisy,
          (value) => settings.pauseNoisy = value,
        ),
        _switch(
          Icons.content_cut_rounded,
          'Skip silence',
          settings.skipSilence,
          (value) => settings.skipSilence = value,
        ),
        _switch(
          Icons.my_location_rounded,
          'Exact seeking',
          settings.exactSeek,
          (value) => settings.exactSeek = value,
        ),
        ChoiceTile<LoopMode>(
          icon: Icons.repeat_rounded,
          title: 'Repeat',
          value: settings.repeat,
          options: <LoopMode, String>{
            for (final mode in LoopMode.values) mode: mode.label,
          },
          onChanged: (value) => settings.repeat = value,
        ),
        ChoiceTile<OrientationMode>(
          icon: Icons.screen_rotation_rounded,
          title: 'Orientation',
          value: settings.orientation,
          options: <OrientationMode, String>{
            for (final mode in OrientationMode.values) mode: mode.label,
          },
          onChanged: (value) => settings.orientation = value,
        ),
        _switch(
          Icons.schedule_rounded,
          'Show clock',
          settings.showClock,
          (value) => settings.showClock = value,
        ),
        _switch(
          Icons.hourglass_bottom_rounded,
          'Show remaining time',
          settings.showRemaining,
          (value) => settings.showRemaining = value,
        ),
        ChoiceTile<int>(
          icon: Icons.speed_rounded,
          title: 'Default speed',
          value: settings.speed,
          options: _speeds,
          onChanged: (value) => settings.speed = value,
        ),
        _switch(
          Icons.save_outlined,
          'Remember speed per video',
          settings.rememberSpeed,
          (value) => settings.rememberSpeed = value,
        ),
        ChoiceTile<AspectMode>(
          icon: Icons.aspect_ratio_rounded,
          title: 'Default aspect ratio',
          value: settings.aspect,
          options: <AspectMode, String>{
            for (final mode in AspectMode.values) mode: mode.label,
          },
          onChanged: (value) => settings.aspect = value,
        ),
        ChoiceTile<int>(
          icon: Icons.timer_outlined,
          title: 'Hide controls after',
          value: settings.hideDelay,
          options: _hideDelays,
          onChanged: (value) => settings.hideDelay = value,
        ),
      ],
    );
  }

  Widget _floating() {
    return SettingsSection(
      title: 'Floating window',
      children: [
        _switch(
          Icons.picture_in_picture_alt_rounded,
          'Open when leaving the app',
          settings.autoFloat,
          (value) => settings.autoFloat = value,
        ),
        _switch(
          Icons.smart_button_rounded,
          'Play/pause button',
          settings.floatControls,
          (value) => settings.floatControls = value,
        ),
        ChoiceTile<FloatShape>(
          icon: Icons.crop_landscape_rounded,
          title: 'Window shape',
          value: settings.floatShape,
          options: <FloatShape, String>{
            for (final shape in FloatShape.values) shape: shape.label,
          },
          onChanged: (value) => settings.floatShape = value,
        ),
      ],
    );
  }

  Widget _gestures() {
    return SettingsSection(
      title: 'Gestures',
      children: [
        _switch(
          Icons.brightness_medium_rounded,
          'Swipe for brightness',
          settings.swipeBrightness,
          (value) => settings.swipeBrightness = value,
        ),
        _switch(
          Icons.volume_up_rounded,
          'Swipe for volume',
          settings.swipeVolume,
          (value) => settings.swipeVolume = value,
        ),
        _switch(
          Icons.swipe_rounded,
          'Swipe to seek',
          settings.swipeSeek,
          (value) => settings.swipeSeek = value,
        ),
        _switch(
          Icons.fast_forward_rounded,
          'Hold for 2× speed',
          settings.longPressSpeed,
          (value) => settings.longPressSpeed = value,
        ),
        ChoiceTile<int>(
          icon: Icons.touch_app_rounded,
          title: 'Double-tap to seek',
          value: settings.doubleTap,
          options: _doubleTaps,
          onChanged: (value) => settings.doubleTap = value,
        ),
      ],
    );
  }

  Widget _subtitles(ThemeData theme) {
    return SettingsSection(
      title: 'Subtitles',
      children: [
        _switch(
          Icons.subtitles_rounded,
          'Show by default',
          settings.subtitles,
          (value) => settings.subtitles = value,
        ),
        ListTile(
          leading: const Icon(Icons.format_size_rounded),
          title: const Text('Text size'),
          trailing: Text(
            '${settings.subtitleSize}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          subtitle: Slider(
            value: settings.subtitleSize.toDouble(),
            min: 14,
            max: 32,
            divisions: 9,
            onChanged: (value) => settings.subtitleSize = value.round(),
          ),
        ),
        _switch(
          Icons.crop_din_rounded,
          'Background box',
          settings.subtitleBox,
          (value) => settings.subtitleBox = value,
        ),
        ChoiceTile<String>(
          icon: Icons.language_rounded,
          title: 'Preferred language',
          value: settings.subtitleLang,
          options: _subtitleLanguages,
          onChanged: (value) => settings.subtitleLang = value,
        ),
        ChoiceTile<SubtitleColor>(
          icon: Icons.palette_outlined,
          title: 'Text color',
          value: settings.subtitleColor,
          options: <SubtitleColor, String>{
            for (final color in SubtitleColor.values) color: color.label,
          },
          onChanged: (value) => settings.subtitleColor = value,
        ),
        ChoiceTile<int>(
          icon: Icons.vertical_align_bottom_rounded,
          title: 'Position',
          value: settings.subtitlePos,
          options: _subtitlePositions,
          onChanged: (value) => settings.subtitlePos = value,
        ),
      ],
    );
  }

  Widget _audio() {
    return SettingsSection(
      title: 'Audio',
      children: [
        ChoiceTile<String>(
          icon: Icons.language_rounded,
          title: 'Preferred language',
          value: settings.audioLang,
          options: _audioLanguages,
          onChanged: (value) => settings.audioLang = value,
        ),
        _switch(
          Icons.volume_up_outlined,
          'Volume boost',
          settings.volumeBoost,
          (value) => settings.volumeBoost = value,
        ),
      ],
    );
  }

  Widget _updates() {
    return SettingsSection(
      title: 'Updates',
      children: [
        SwitchListTile(
          title: const Text('Check for updates'),
          subtitle: const Text('Look for a newer version when the app starts'),
          value: settings.checkUpdates,
          onChanged: (value) => settings.checkUpdates = value,
        ),
      ],
    );
  }

  Widget _data(BuildContext context) {
    return SettingsSection(
      title: 'Data',
      children: [
        _action(
          context,
          Icons.history_toggle_off_rounded,
          'Clear watch history',
          'History cleared',
          library.clearHistory,
        ),
        _action(
          context,
          Icons.heart_broken_outlined,
          'Clear favorites',
          'Favorites cleared',
          library.clearFavorites,
        ),
        _action(
          context,
          Icons.restore_rounded,
          'Reset settings',
          'Settings reset',
          settings.reset,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                _appearance(),
                if (L10n.languages.length > 1) _language(context),
                _library(),
                _playback(),
                _music(),
                _floating(),
                _defaults(context),
                _gestures(),
                _subtitles(theme),
                _audio(),
                _updates(),
                _data(context),
              ],
            ),
          ),
        );
      },
    );
  }

  String _languageName(String code) {
    if (code == L10n.system) return 'System default'.tr;
    for (final language in L10n.languages) {
      if (language.code == code) return language.name;
    }
    return code;
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final picked = await showLanguageSheet(context, settings.language);
    if (picked != null) settings.language = picked;
  }
}


class _ScaleTile extends StatefulWidget {
  const _ScaleTile({required this.settings});

  final AppSettings settings;

  @override
  State<_ScaleTile> createState() => _ScaleTileState();
}

class _ScaleTileState extends State<_ScaleTile> {
  static const double _min = 70;
  static const double _max = 120;

  double? _drag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _drag ?? widget.settings.uiScale.toDouble();
    return ListTile(
      leading: const Icon(Icons.zoom_in_rounded),
      title: const Text('Interface size'),
      trailing: Text(
        '${value.round()}%',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Slider(
        value: value,
        min: _min,
        max: _max,
        divisions: 10,
        onChanged: (next) => setState(() => _drag = next),
        onChangeEnd: (next) {
          widget.settings.uiScale = next.round();
          setState(() => _drag = null);
        },
      ),
    );
  }
}


class _AccentTile extends StatelessWidget {
  const _AccentTile({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final palette = dark ? CatppuccinPalette.mocha : CatppuccinPalette.latte;
    return ListTile(
      leading: const Icon(Icons.color_lens_outlined),
      title: const Text('Accent color'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final name in CatppuccinPalette.accents)
              _Dot(
                color: palette.accent(name),
                selected: settings.accent == name,
                onTap: () => settings.accent = name,
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.d(200),
        curve: Curves.easeOut,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? outline : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: AppMotion.d(200),
          curve: Curves.easeOutBack,
          child: Icon(
            Icons.check_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }
}

class _GridTile extends StatefulWidget {
  const _GridTile({required this.settings});

  final AppSettings settings;

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _drag ?? widget.settings.gridSize.toDouble();
    return ListTile(
      leading: const Icon(Icons.grid_on_rounded),
      title: const Text('Grid tile size'),
      trailing: Text(
        '${value.round()}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Slider(
        value: value,
        min: 140,
        max: 360,
        divisions: 11,
        onChanged: (next) => setState(() => _drag = next),
        onChangeEnd: (next) {
          widget.settings.gridSize = next.round();
          setState(() => _drag = null);
        },
      ),
    );
  }
}
