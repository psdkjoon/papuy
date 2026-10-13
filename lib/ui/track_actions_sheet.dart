import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/ui/details_dialog.dart';
import 'package:papuy/ui/playlist_picker.dart';
import 'package:papuy/ui/widgets/favorite_button.dart';

Future<void> showTrackActions(
  BuildContext context,
  MusicController music,
  TrackItem track, {
  VoidCallback? onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void close() => Navigator.of(sheetContext).pop();
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: track.artist.isEmpty ? null : Text(track.artist),
              ),
              ListenableBuilder(
                listenable: music.data,
                builder: (context, _) {
                  final favorite = music.data.isFavorite(track.id);
                  void toggle() => music.data.toggleFavorite(track.id);
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 6, right: 16),
                    leading: FavoriteButton(
                      favorite: favorite,
                      size: 22,
                      onPressed: toggle,
                    ),
                    title: Text(
                      favorite ? 'Remove from favorites' : 'Add to favorites',
                    ),
                    onTap: toggle,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Add to playlist'),
                onTap: () {
                  close();
                  showPlaylistPicker(context, music, <int>[track.id]);
                },
              ),
              if (onRemove != null)
                ListTile(
                  leading: const Icon(Icons.playlist_remove_rounded),
                  title: const Text('Remove from playlist'),
                  onTap: () {
                    close();
                    onRemove();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: const Text('Play next'),
                onTap: () {
                  close();
                  music.playNext(track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: const Text('Add to queue'),
                onTap: () {
                  close();
                  music.enqueue(track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () {
                  close();
                  MediaService.share(track.uri, type: 'audio/*');
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
                      'Title': track.title,
                      if (track.artist.isNotEmpty) 'Artist': track.artist,
                      if (track.album.isNotEmpty) 'Album': track.album,
                      if (track.durationMs > 0)
                        'Duration': formatDuration(track.duration),
                      if (track.name.isNotEmpty) 'File': track.name,
                      'Source': track.uri,
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
