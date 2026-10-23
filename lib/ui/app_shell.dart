import 'dart:async';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:flutter/services.dart';
import 'package:papuy/app_info.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/platform/notification_service.dart';
import 'package:papuy/platform/system_service.dart';
import 'package:papuy/platform/window_service.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/music_screen.dart';
import 'package:papuy/ui/now_playing_screen.dart';
import 'package:papuy/ui/player_screen.dart';
import 'package:papuy/ui/settings_screen.dart';
import 'package:papuy/ui/update_prompt.dart';
import 'package:papuy/ui/videos_screen.dart';
import 'package:papuy/ui/widgets/music_dock_view.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.settings,
    required this.library,
    required this.music,
    super.key,
  });

  final AppSettings settings;
  final LibraryController library;
  final MusicController music;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _sidebarBreakpoint = 800;
  static const _destinations = [
    _Destination('Videos', Icons.movie_outlined, Icons.movie_rounded),
    _Destination('Music', Icons.library_music_outlined, Icons.library_music_rounded),
    _Destination('Settings', Icons.tune_rounded, Icons.tune_rounded),
  ];

  static var _lastIndex = 0;

  var _index = _lastIndex;

  bool _fullStarted = false;

  void _select(int index) {
    if (!mounted) return;
    setState(() => _index = _lastIndex = index);
  }

  @override
  void initState() {
    super.initState();
    MediaService.incoming.addListener(_onIncoming);
    WindowService.homeRequests.addListener(_goHome);
    WindowService.handoffRequests.addListener(_onHandoff);
    WindowService.playerRequests.addListener(_openPlayer);
    unawaited(_boot());
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPlayer());
  }

  @override
  void dispose() {
    MediaService.incoming.removeListener(_onIncoming);
    WindowService.homeRequests.removeListener(_goHome);
    WindowService.handoffRequests.removeListener(_onHandoff);
    WindowService.playerRequests.removeListener(_openPlayer);
    super.dispose();
  }

  Future<void> _boot() async {
    final launch = await MediaService.takeLaunch();
    if (!mounted) return;
    if (launch != null && launch.quick) {
      MediaService.quickRequest.value = launch;
      return;
    }
    _startFull();
    if (launch != null) await _openExternal(launch);
  }

  void _startFull() {
    if (_fullStarted) return;
    _fullStarted = true;
    if (AppInfo.usesNotifications || AppInfo.usesBackground) {
      NotificationService.requestPermission();
    }
    if (AppInfo.usesBackground) unawaited(_askBackground());
    unawaited(widget.library.load(ask: true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      UpdatePrompt.run(context, widget.settings);
    });
  }

  Future<void> _askBackground() async {
    if (widget.settings.backgroundAsked) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || widget.settings.backgroundAsked) return;
    final allow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.battery_charging_full_rounded, size: 32),
        title: const Text('Keep playing in the background?'),
        content: const Text(
          'Android may stop playback when the screen is off to save battery. Allow Papuy to keep running? A system settings page will open.',
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.schedule_rounded),
            label: const Text('Not now'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('Continue'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    widget.settings.backgroundAsked = true;
    if (allow == true) unawaited(SystemService.requestBackgroundAccess());
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _startFull();
  }

  void _openPlayer() {
    if (!WindowService.playerRequested || !mounted) return;
    WindowService.playerRequested = false;
    if (WindowService.playerOpen.value || !widget.music.hasTrack) return;
    unawaited(NowPlayingScreen.open(context, widget.music));
  }

  void _onHandoff() {
    final incoming = MediaService.handoff;
    MediaService.handoff = null;
    if (!mounted) return;
    _startFull();
    if (incoming != null) unawaited(_openExternal(incoming));
  }

  void _onIncoming() {
    final incoming = MediaService.incoming.value;
    if (incoming == null || !mounted) return;
    MediaService.incoming.value = null;
    if (incoming.quick) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      MediaService.quickRequest.value = incoming;
      return;
    }
    _startFull();
    unawaited(_openExternal(incoming));
  }

  Future<void> _openExternal(IncomingVideo incoming) async {
    if (TrackItem.isAudioFile(incoming.name, incoming.mime)) {
      _select(1);
      if (widget.music.track?.uri != incoming.uri) {
        await widget.music.playSingle(
          TrackItem.external(incoming.uri, incoming.name),
        );
      }
      if (mounted) await NowPlayingScreen.open(context, widget.music);
      return;
    }
    await PlayerScreen.open(
      context,
      settings: widget.settings,
      library: widget.library,
      playlist: <VideoItem>[VideoItem.external(incoming.uri, incoming.name)],
      index: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = SafeArea(
      bottom: false,
      child: MusicDockView(
        music: widget.music,
        child: IndexedStack(
          index: _index,
          children: [
            VideosScreen(
              settings: widget.settings,
              library: widget.library,
              music: widget.music,
            ),
            MusicScreen(
              settings: widget.settings,
              library: widget.library,
              music: widget.music,
            ),
            SettingsScreen(settings: widget.settings, library: widget.library),
          ],
        ),
      ),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: theme.colorScheme.surfaceContainerLow,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    final Widget scaffold;
    if (MediaQuery.sizeOf(context).width >= _sidebarBreakpoint) {
      scaffold = Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              destinations: _destinations,
              selectedIndex: _index,
              onSelected: _select,
            ),
            Expanded(child: page),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        body: page,
        bottomNavigationBar: _CompactBar(
          destinations: _destinations,
          selectedIndex: _index,
          onSelected: _select,
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: scaffold,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _width = 11 * AppSpacing.spaceUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: _width,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      AppInfo.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                for (var i = 0; i < destinations.length; i++)
                  ListTile(
                    selected: i == selectedIndex,
                    leading: Icon(
                      i == selectedIndex
                          ? destinations[i].selectedIcon
                          : destinations[i].icon,
                    ),
                    title: Text(destinations[i].label),
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactBar extends StatelessWidget {
  const _CompactBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _CompactItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactItem extends StatelessWidget {
  const _CompactItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  static const double _pillHeight = 40;
  static const Duration _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label.tr,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onTap,
            child: AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOutCubic,
              height: _pillHeight,
              constraints: const BoxConstraints(minWidth: 48),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? AppSpacing.md : AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? scheme.secondaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: AnimatedSize(
                duration: _duration,
                curve: Curves.easeOutCubic,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: color,
                    ),
                    if (selected)
                      Text(
                        destination.label,
                        style: theme.textTheme.labelLarge?.copyWith(color: color),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
