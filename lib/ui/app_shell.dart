import 'dart:async';

import 'package:flutter/material.dart';
import 'package:papuy/app_info.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/platform/notification_service.dart';
import 'package:papuy/platform/window_service.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/ui/music_screen.dart';
import 'package:papuy/ui/now_playing_screen.dart';
import 'package:papuy/ui/player_screen.dart';
import 'package:papuy/ui/update_prompt.dart';
import 'package:papuy/ui/videos_screen.dart';
import 'package:papuy/ui/widgets/mini_player.dart';

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
  final ValueNotifier<int> _mode = ValueNotifier<int>(0);

  bool _fullStarted = false;

  @override
  void initState() {
    super.initState();
    MediaService.incoming.addListener(_onIncoming);
    WindowService.homeRequests.addListener(_goHome);
    WindowService.handoffRequests.addListener(_onHandoff);
    unawaited(_boot());
  }

  @override
  void dispose() {
    MediaService.incoming.removeListener(_onIncoming);
    WindowService.homeRequests.removeListener(_goHome);
    WindowService.handoffRequests.removeListener(_onHandoff);
    _mode.dispose();
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
    if (AppInfo.usesNotifications) NotificationService.requestPermission();
    unawaited(widget.library.load(ask: true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      UpdatePrompt.run(context, widget.settings);
    });
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _startFull();
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
      _mode.value = 1;
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
    final body = ValueListenableBuilder<int>(
      valueListenable: _mode,
      builder: (context, mode, _) => mode == 0
          ? VideosScreen(
              key: const ValueKey<int>(0),
              settings: widget.settings,
              library: widget.library,
              mode: _mode,
            )
          : MusicScreen(
              key: const ValueKey<int>(1),
              settings: widget.settings,
              library: widget.library,
              music: widget.music,
              mode: _mode,
            ),
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: widget.music,
                child: body,
                builder: (context, child) => MediaQuery.removePadding(
                  context: context,
                  removeBottom: widget.music.hasTrack,
                  child: child!,
                ),
              ),
            ),
            MiniPlayer(music: widget.music),
          ],
        ),
      ),
    );
  }
}
