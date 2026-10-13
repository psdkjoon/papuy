import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/widgets/track_art.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    required this.track,
    required this.onTap,
    this.onLongPress,
    this.current = false,
    this.playing = false,
    this.showAlbum = true,
    super.key,
  });

  final TrackItem track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool current;
  final bool playing;
  final bool showAlbum;

  static const double _artSize = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = showAlbum ? track.subtitle : track.artist;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxs,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            TrackArt(track: track, size: _artSize),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: current ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (current)
              Icon(
                playing ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                size: 18,
                color: scheme.primary,
              ),
            if (track.durationMs > 0)
              Text(
                formatDuration(track.duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
