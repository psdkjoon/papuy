import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/video_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/ui/details_dialog.dart';

Future<void> showVideoActions(
  BuildContext context,
  LibraryController library,
  VideoItem video,
  VoidCallback onPlay,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void close() => Navigator.of(sheetContext).pop();
      final favorite = library.isFavorite(video);
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  library.title(video),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Play'),
                onTap: () {
                  close();
                  onPlay();
                },
              ),
              if (!video.isExternal)
                ListTile(
                  leading: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                  title: Text(
                    favorite ? 'Remove from favorites' : 'Add to favorites',
                  ),
                  onTap: () {
                    library.toggleFavorite(video);
                    close();
                  },
                ),
              if (library.position(video) > 0)
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text('Forget position'),
                  onTap: () {
                    library.forgetPosition(video);
                    close();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () {
                  close();
                  MediaService.share(video.uri);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Details'),
                onTap: () {
                  close();
                  showDetailsDialog(
                    context,
                    title: 'Details',
                    rows: <String, String>{
                      'Name': video.name,
                      'Folder': video.folder,
                      if (video.durationMs > 0)
                        'Duration': formatDuration(video.duration),
                      if (video.width > 0)
                        'Size': '${video.width}×${video.height}',
                      if (video.sizeBytes > 0) 'File': video.info,
                      'Source': video.uri,
                    },
                  );
                },
              ),
              if (!video.isExternal)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Delete'),
                  onTap: () {
                    close();
                    _confirmDelete(context, library, video);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  LibraryController library,
  VideoItem video,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete video?'),
      content: Text(video.name),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final deleted = await MediaService.delete(video.uri);
  if (!deleted) return;
  library.forgetPosition(video);
  await library.load();
}
