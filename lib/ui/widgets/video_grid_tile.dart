import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/widgets/video_thumb.dart';

class VideoGridTile extends StatelessWidget {
  const VideoGridTile({
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

  static const double padding = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.xxs,
          children: [
            VideoThumb(video: video, library: library),
            Flexible(
              child: Text(
                library.title(video),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              video.info,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
