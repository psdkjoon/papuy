import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/platform/system_service.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/theme/app_motion.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/theme/app_theme.dart';
import 'package:papuy/ui/widgets/animated_play_icon.dart';
import 'package:papuy/ui/widgets/player_surface_view.dart';
import 'package:papuy/ui/widgets/track_art.dart';

class QuickShell extends StatefulWidget {
  const QuickShell({
    required this.request,
    required this.settings,
    required this.library,
    required this.music,
    super.key,
  });

  final IncomingVideo request;
  final AppSettings settings;
  final LibraryController library;
  final MusicController music;

  @override
  State<QuickShell> createState() => _QuickShellState();
}

class _QuickShellState extends State<QuickShell> {
  static const double _maxWidth = 480;
  static const double _balanceWidth = 96;

  late final bool _audio =
      TrackItem.isAudioFile(widget.request.name, widget.request.mime);
  late final TrackItem _item =
      TrackItem.external(widget.request.uri, widget.request.name);
  PlayerController? _video;
  bool _handedOff = false;

  MusicController get _music => widget.music;

  @override
  void initState() {
    super.initState();
    if (_audio) {
      if (_music.track?.uri != _item.uri) unawaited(_music.playSingle(_item));
    } else {
      final controller = PlayerController(
        settings: widget.settings,
        library: widget.library,
        playlist: <VideoItem>[
          VideoItem.external(widget.request.uri, widget.request.name),
        ],
        index: 0,
        quick: true,
      );
      _video = controller..start();
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _dismiss() => unawaited(SystemService.closeQuick());

  Future<void> _stop() async {
    if (_audio) await _music.stop();
    _dismiss();
  }

  Future<void> _openApp() async {
    final controller = _video;
    if (controller != null) {
      widget.library.savePosition(
        controller.video,
        controller.position.inMilliseconds,
      );
    }
    if (controller != null) {
      setState(() => _handedOff = true);
      await WidgetsBinding.instance.endOfFrame;
      controller.dispose();
      _video = null;
    }
    MediaService.handoff = widget.request;
    await SystemService.openFull();
  }

  Widget _seek(
    ThemeData theme, {
    required Duration position,
    required int durationMs,
    required VoidCallback onStart,
    required ValueChanged<Duration> onPreview,
    required ValueChanged<Duration> onEnd,
  }) {
    final total = (durationMs > 0 ? durationMs : 1) / 1000.0;
    final current =
        (position.inMilliseconds / 1000.0).clamp(0.0, total).toDouble();
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Row(
      children: [
        Text(formatDuration(position), style: style),
        Expanded(
          child: Slider(
            value: current,
            max: total,
            onChangeStart: (_) => onStart(),
            onChanged: (value) =>
                onPreview(Duration(milliseconds: (value * 1000).round())),
            onChangeEnd: (value) =>
                onEnd(Duration(milliseconds: (value * 1000).round())),
          ),
        ),
        Text(formatDuration(Duration(milliseconds: durationMs)), style: style),
      ],
    );
  }

  Widget _header(ThemeData theme, Widget leading, String title, String sub) {
    return Row(
      spacing: AppSpacing.md,
      children: [
        leading,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Stop'.tr,
          icon: const Icon(Icons.close_rounded),
          onPressed: _stop,
        ),
      ],
    );
  }

  Widget _audioCard(ThemeData theme) {
    return ListenableBuilder(
      listenable: _music,
      builder: (context, _) {
        final track = _music.track ?? _item;
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            _header(
              theme,
              TrackArt(track: track, size: 56, radius: 14),
              track.title,
              track.artist,
            ),
            _seek(
              theme,
              position: _music.position,
              durationMs: _music.durationMs,
              onStart: _music.startScrub,
              onPreview: _music.previewScrub,
              onEnd: _music.endScrub,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
                  label: const Text('Open app'),
                  onPressed: _openApp,
                ),
                IconButton.filled(
                  iconSize: 32,
                  style: IconButton.styleFrom(
                    fixedSize: const Size(56, 56),
                  ),
                  icon: _music.loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : AnimatedPlayIcon(playing: _music.playing),
                  onPressed: _music.togglePlay,
                ),
                const SizedBox(width: _balanceWidth),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _videoCard(ThemeData theme) {
    final controller = _video!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final width = controller.displayWidth * controller.pixelRatio;
        final height = controller.displayHeight.toDouble();
        final ratio = height > 0 && width > 0 ? width / height : 16 / 9;
        final limit = MediaQuery.sizeOf(context).height * 0.5;
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: limit),
              child: AnimatedSize(
                duration: AppMotion.d(250),
                curve: Curves.easeOutCubic,
                child: AspectRatio(
                  aspectRatio: ratio.clamp(0.6, 2.4).toDouble(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: theme.extension<StatusColors>()!.scrim,
                        ),
                        PlayerSurfaceView(controller: controller),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: controller.togglePlay,
                        ),
                        if (controller.loading || controller.buffering)
                          const Center(child: CircularProgressIndicator()),
                        if (controller.failed)
                          Center(
                            child: Text(
                              "Can't play this video",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.extension<StatusColors>()!.onScrim,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _header(
              theme,
              IconButton.filled(
                icon: AnimatedPlayIcon(playing: controller.playing),
                onPressed: controller.togglePlay,
              ),
              widget.request.name,
              '',
            ),
            _seek(
              theme,
              position: controller.position,
              durationMs: controller.durationMs,
              onStart: controller.startScrub,
              onPreview: controller.previewScrub,
              onEnd: controller.endScrub,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_full_rounded, size: 18),
                label: const Text('Open app'),
                onPressed: _openApp,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_handedOff) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final inset = MediaQuery.paddingOf(context);
    return Material(
      type: MaterialType.transparency,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: AppMotion.d(320),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: ColoredBox(
                  color: theme
                      .extension<StatusColors>()!
                      .scrim
                      .withValues(alpha: 0.5 * value),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 48),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md + inset.left,
            AppSpacing.md,
            AppSpacing.md + inset.right,
            AppSpacing.md + math.max(inset.bottom, 0),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Material(
              color: theme.colorScheme.surfaceContainerHigh,
              elevation: 6,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: _audio ? _audioCard(theme) : _videoCard(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
