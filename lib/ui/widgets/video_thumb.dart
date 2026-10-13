import 'dart:typed_data';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/thumbnail_cache.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/theme/app_theme.dart';

class VideoThumb extends StatelessWidget {
  const VideoThumb({required this.video, required this.library, super.key});

  final VideoItem video;
  final LibraryController library;

  static const double _heartSize = 16;
  static const double _barHeight = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tints = <Color>[scheme.primary, scheme.secondary, scheme.tertiary];
    final first = tints[video.id % tints.length];
    final second = tints[(video.id + 1) % tints.length];
    final progress = library.progress(video);
    final watched = progress > 0 && progress < 1;
    final heart = theme.extension<StatusColors>()!.heart;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surfaceContainerHighest),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    first.withValues(alpha: 0.55),
                    second.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            if (library.settings.showThumbnails)
              FutureBuilder<Uint8List?>(
                future: ThumbnailCache.of(video.id),
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes == null) return const SizedBox.shrink();
                  return Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  );
                },
              ),
            if (library.isFavorite(video))
              Positioned(
                left: AppSpacing.xxs,
                top: AppSpacing.xxs,
                child: Icon(
                  Icons.favorite_rounded,
                  size: _heartSize,
                  color: heart,
                ),
              ),
            if (video.durationMs > 0)
              Positioned(
                right: AppSpacing.xxs,
                bottom: watched ? AppSpacing.sm : AppSpacing.xxs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(AppRadius.tile / 4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
                    child: Text(
                      formatDuration(video.duration),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (watched)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: _barHeight,
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
