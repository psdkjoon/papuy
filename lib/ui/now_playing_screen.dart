import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/settings/loop_mode.dart';
import 'package:papuy/theme/app_motion.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/playlist_picker.dart';
import 'package:papuy/ui/queue_sheet.dart';
import 'package:papuy/ui/widgets/choice_sheet.dart';
import 'package:papuy/ui/widgets/animated_play_icon.dart';
import 'package:papuy/ui/widgets/favorite_button.dart';
import 'package:papuy/ui/widgets/pop_icon.dart';
import 'package:papuy/ui/widgets/slide_fade_transitions.dart';
import 'package:papuy/ui/widgets/sleep_picker.dart';
import 'package:papuy/ui/widgets/spectrum_view.dart';
import 'package:papuy/ui/widgets/track_art.dart';

const Map<int, String> _speeds = <int, String>{
  75: '0.75×',
  100: '1.0×',
  125: '1.25×',
  150: '1.5×',
  200: '2.0×',
};

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({required this.music, super.key});

  final MusicController music;

  static bool _showing = false;

  static Future<void> open(BuildContext context, MusicController music) {
    if (_showing) return Future<void>.value();
    _showing = true;
    return Navigator.of(context)
        .push(
          RiseRoute<void>(
            settings: const RouteSettings(name: 'now_playing'),
            builder: (_) => NowPlayingScreen(music: music),
          ),
        )
        .whenComplete(() => _showing = false);
  }

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  static const double _maxArt = 340;
  static const double _playButton = 60;

  MusicController get _music => widget.music;

  Widget _art() {
    final track = _music.track!;
    return LayoutBuilder(
      builder: (context, box) {
        final height = box.hasBoundedHeight ? box.maxHeight : _maxArt;
        final side = math.min(math.min(box.maxWidth, height), _maxArt);
        return AnimatedSwitcher(
          duration: AppMotion.d(380),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: SizedBox.square(
            key: ValueKey<int>(track.id),
            dimension: side,
            child: TrackArt(track: track, radius: 28, pixels: 512),
          ),
        );
      },
    );
  }

  Widget _titles(ThemeData theme) {
    final track = _music.track!;
    return AnimatedSwitcher(
      duration: AppMotion.d(300),
      child: Column(
      key: ValueKey<int>(track.id),
      spacing: AppSpacing.xxs,
      children: [
        Text(
          track.title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall,
        ),
        if (track.subtitle.isNotEmpty)
          Text(
            track.subtitle,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        if (_music.failed)
          Text(
            "Can't play this file",
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
      ],
    ),
    );
  }

  Widget _seekBar(ThemeData theme) {
    final total = (_music.durationMs > 0 ? _music.durationMs : 1) / 1000.0;
    final current =
        (_music.position.inMilliseconds / 1000.0).clamp(0.0, total).toDouble();
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Row(
      children: [
        Text(formatDuration(_music.position), style: style),
        Expanded(
          child: Slider(
            value: current,
            max: total,
            onChangeStart: (_) => _music.startScrub(),
            onChanged: (value) => _music.previewScrub(
              Duration(milliseconds: (value * 1000).round()),
            ),
            onChangeEnd: (value) => _music.endScrub(
              Duration(milliseconds: (value * 1000).round()),
            ),
          ),
        ),
        Text(
          formatDuration(Duration(milliseconds: _music.durationMs)),
          style: style,
        ),
      ],
    );
  }

  Future<void> _pickSpeed() async {
    final picked = await showChoices<int>(
      context,
      title: 'Speed',
      value: (_music.speed * 100).round(),
      options: _speeds,
    );
    if (picked != null) await _music.setSpeed(picked / 100);
  }

  Future<void> _pickSleep() async {
    final picked = await pickSleepMinutes(context);
    if (picked != null) _music.setSleepTimer(picked);
  }

  Widget _sleepButton(ThemeData theme) {
    final scheme = theme.colorScheme;
    final left = _music.sleepLeft;
    final active = left != null;
    return IconButton(
      tooltip: 'Sleep timer'.tr,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      color: active ? scheme.primary : scheme.onSurfaceVariant,
      onPressed: _pickSleep,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  CircularProgressIndicator(
                    value: _music.sleepProgress,
                    strokeWidth: 2,
                    backgroundColor: scheme.primary.withValues(alpha: 0.18),
                  ),
                Icon(
                  active ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                  size: 20,
                ),
              ],
            ),
          ),
          if (active)
            Text(
              formatDuration(left),
              style: theme.textTheme.labelSmall
                  ?.copyWith(height: 1, color: scheme.primary),
            ),
        ],
      ),
    );
  }

  Widget _transport(ThemeData theme) {
    final scheme = theme.colorScheme;
    final repeat = _music.repeat;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FavoriteButton(
          size: 20,
          favorite: _music.data.isFavorite(_music.track!.id),
          onPressed: () {
            _music.haptic();
            _music.data.toggleFavorite(_music.track!.id);
          },
        ),
        IconButton(
          tooltip: 'Shuffle'.tr,
          visualDensity: VisualDensity.compact,
          icon: PopIcon(
            icon: Icons.shuffle_rounded,
            color: _music.shuffle ? scheme.primary : scheme.onSurfaceVariant,
          ),
          onPressed: () {
            _music.haptic();
            _music.toggleShuffle();
          },
        ),
        IconButton(
          tooltip: 'Previous'.tr,
          iconSize: 32,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: () {
            _music.haptic();
            _music.previous();
          },
        ),
        IconButton.filled(
          tooltip: _music.playing ? 'Pause'.tr : 'Play'.tr,
          iconSize: 36,
          style: IconButton.styleFrom(
            fixedSize: const Size(_playButton, _playButton),
          ),
          icon: _music.loading
              ? SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: scheme.onPrimary,
                  ),
                )
              : AnimatedPlayIcon(playing: _music.playing),
          onPressed: () {
            _music.haptic();
            _music.togglePlay();
          },
        ),
        IconButton(
          tooltip: 'Next'.tr,
          iconSize: 32,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: () {
            _music.haptic();
            _music.next();
          },
        ),
        IconButton(
          tooltip: repeat.toast.tr,
          visualDensity: VisualDensity.compact,
          icon: PopIcon(
            icon: repeat == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: repeat == LoopMode.off
                ? scheme.onSurfaceVariant
                : scheme.primary,
          ),
          onPressed: () {
            _music.haptic();
            _music.cycleRepeat();
          },
        ),
        _sleepButton(theme),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_music, _music.data]),
      builder: (context, _) {
        if (!_music.hasTrack) {
          final route = ModalRoute.of(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || route == null) return;
            final navigator = Navigator.of(context);
            if (route.isCurrent) {
              navigator.pop();
            } else {
              navigator.removeRoute(route);
            }
          });
          return const Scaffold();
        }
        final theme = Theme.of(context);
        final landscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final controls = Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            _titles(theme),
            if (_music.settings.musicVisualizer)
              SpectrumView(
                active: _music.playing && !_music.loading,
                height: landscape ? 40 : 56,
              ),
            _seekBar(theme),
            _transport(theme),
          ],
        );
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Close'.tr,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text('Now playing'),
            actions: [
              TextButton(
                onPressed: _pickSpeed,
                child: Text('${_music.speedLabel}×'),
              ),
              IconButton(
                tooltip: 'Queue'.tr,
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: () => showQueueSheet(context, _music),
              ),
              IconButton(
                tooltip: 'Add to playlist'.tr,
                icon: const Icon(Icons.playlist_add_rounded),
                onPressed: () => showPlaylistPicker(
                  context,
                  _music,
                  <int>[_music.track!.id],
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: landscape
                  ? Row(
                      spacing: AppSpacing.xl,
                      children: [
                        Expanded(child: Center(child: _art())),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(child: controls),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      spacing: AppSpacing.md,
                      children: [
                        Expanded(child: Center(child: _art())),
                        controls,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
