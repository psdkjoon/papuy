import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/theme/app_motion.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/now_playing_screen.dart';
import 'package:papuy/ui/widgets/animated_play_icon.dart';
import 'package:papuy/ui/widgets/track_art.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({required this.music, super.key});

  final MusicController music;

  static const double _artSize = 40;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: music,
      builder: (context, _) {
        final track = music.track;
        return AnimatedSwitcher(
          duration: AppMotion.d(300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: track == null
              ? const SizedBox.shrink(key: ValueKey<String>('none'))
              : _body(context, track),
        );
      },
    );
  }

  Widget _body(BuildContext context, TrackItem track) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = music.durationMs > 0 ? music.durationMs : 1;
    final progress = (music.position.inMilliseconds / total)
        .clamp(0.0, 1.0)
        .toDouble();
    return Material(
      key: const ValueKey<String>('mini'),
      color: scheme.surfaceContainerHigh,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.tile),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => NowPlayingScreen.open(context, music),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress, minHeight: 2),
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.xxs,
                bottom: AppSpacing.xxs + MediaQuery.paddingOf(context).bottom,
              ),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  TrackArt(track: track, size: _artSize, radius: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                        Row(
                          spacing: AppSpacing.xxs,
                          children: [
                            if (music.sleepLeft != null) ...[
                              Icon(
                                Icons.bedtime_rounded,
                                size: 12,
                                color: scheme.primary,
                              ),
                              Text(
                                formatDuration(music.sleepLeft!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                            if (track.artist.isNotEmpty)
                              Expanded(
                                child: Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: (music.playing ? 'Pause' : 'Play').tr,
                    icon: AnimatedPlayIcon(playing: music.playing),
                    onPressed: music.togglePlay,
                  ),
                  IconButton(
                    tooltip: 'Next'.tr,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: music.next,
                  ),
                  IconButton(
                    tooltip: 'Stop'.tr,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: music.stop,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
