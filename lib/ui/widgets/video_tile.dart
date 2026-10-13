import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/widgets/video_thumb.dart';

class VideoTile extends StatelessWidget {
  const VideoTile({
    required this.video,
    required this.library,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final VideoItem video;
  final LibraryController library;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static const double _thumbWidth = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            SizedBox(
              width: _thumbWidth,
              child: VideoThumb(video: video, library: library),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    library.title(video),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    video.info,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
