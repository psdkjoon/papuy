import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/platform/window_service.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/theme/app_theme.dart';
import 'package:papuy/ui/player_menu_sheet.dart';
import 'package:papuy/ui/player_speed_sheet.dart';
import 'package:papuy/ui/track_sheet.dart';
import 'package:papuy/ui/widgets/player_bottom_bar.dart';
import 'package:papuy/ui/widgets/player_center_controls.dart';
import 'package:papuy/ui/widgets/player_surface_view.dart';
import 'package:papuy/ui/widgets/player_top_bar.dart';
import 'package:papuy/ui/widgets/subtitle_overlay.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    required this.settings,
    required this.library,
    required this.playlist,
    required this.index,
    super.key,
  });

  final AppSettings settings;
  final LibraryController library;
  final List<VideoItem> playlist;
  final int index;

  static Future<void> open(
    BuildContext context, {
    required AppSettings settings,
    required LibraryController library,
    required List<VideoItem> playlist,
    required int index,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          settings: settings,
          library: library,
          playlist: playlist,
          index: index,
        ),
      ),
    );
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const double _miniWidth = 200;
  static const double _miniHeight = 120;
  static const Alignment _toastAlignment = Alignment(0, -0.5);

  late final PlayerController _controller = PlayerController(
    settings: widget.settings,
    library: widget.library,
    playlist: widget.playlist,
    index: widget.index,
  );

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _gestures(double width) {
    final c = _controller;
    final locked = c.locked;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: c.toggleControls,
      onDoubleTapDown: locked ? null : (d) => c.onTapDown(d.localPosition.dx),
      onDoubleTap: locked ? null : () => c.onDoubleTap(width),
      onVerticalDragStart: locked
          ? null
          : (d) => c.onVerticalDragStart(d.localPosition.dx, width),
      onVerticalDragUpdate: locked ? null : (d) => c.onVerticalDragUpdate(d.delta.dy),
      onHorizontalDragStart: locked ? null : (_) => c.onHorizontalDragStart(),
      onHorizontalDragUpdate:
          locked ? null : (d) => c.onHorizontalDragUpdate(d.delta.dx),
      onHorizontalDragEnd: locked ? null : (_) => c.onHorizontalDragEnd(),
      onLongPressStart: locked ? null : (_) => c.onHoldStart(),
      onLongPressEnd: locked ? null : (_) => c.onHoldEnd(),
    );
  }

  StatusColors get _status => Theme.of(context).extension<StatusColors>()!;

  Widget _failure() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Can't play this video",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: _status.onScrim),
          ),
          TextButton(onPressed: _controller.open, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _toast(String text) {
    return IgnorePointer(
      child: Align(
        alignment: _toastAlignment,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _status.onScrim,
            shadows: const [Shadow(blurRadius: 6)],
          ),
        ),
      ),
    );
  }

  Widget _lockButton() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: IconButton.filledTonal(
          tooltip: 'Unlock'.tr,
          icon: const Icon(Icons.lock_rounded),
          onPressed: _controller.toggleLock,
        ),
      ),
    );
  }

  Widget _controls({required bool visible}) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: !visible,
        child: Material(
          type: MaterialType.transparency,
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(foregroundColor: _status.onScrim),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: PlayerTopBar(
                    controller: _controller,
                    onMore: () => showPlayerMenu(context, _controller),
                  ),
                ),
                Center(child: PlayerCenterControls(controller: _controller)),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: PlayerBottomBar(
                    controller: _controller,
                    onSpeed: () => showSpeedSheet(context, _controller),
                    onTracks: () => showTrackSheet(context, _controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _status.scrim,
      body: LayoutBuilder(
        builder: (context, box) {
          return ListenableBuilder(
            listenable: Listenable.merge([_controller, WindowService.inPip]),
            builder: (context, _) {
              final mini = WindowService.inPip.value ||
                  box.maxWidth < _miniWidth ||
                  box.maxHeight < _miniHeight;
              final c = _controller;
              final showControls = (c.controlsVisible || c.failed) && !mini;
              final toast = c.toast;
              return Stack(
                fit: StackFit.expand,
                children: [
                  PlayerSurfaceView(controller: c),
                  _gestures(box.maxWidth),
                  SubtitleOverlay(text: c.cueText, settings: c.settings),
                  if (c.loading || (c.buffering && !c.failed))
                    const Center(child: CircularProgressIndicator()),
                  if (c.failed) _failure(),
                  if (toast != null && !mini) _toast(toast),
                  if (c.locked && c.controlsVisible && !mini) _lockButton(),
                  if (!c.locked) _controls(visible: showControls),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
