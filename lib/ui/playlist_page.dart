import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/library/m3u_export.dart';
import 'package:papuy/library/music_store.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/name_dialog.dart';
import 'package:papuy/ui/now_playing_screen.dart';
import 'package:papuy/ui/track_actions_sheet.dart';
import 'package:papuy/ui/widgets/page_frame.dart';
import 'package:papuy/ui/widgets/sub_page.dart';
import 'package:papuy/ui/widgets/track_tile.dart';

enum _PlaylistAction { export, share, rename, delete }

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({
    required this.playlist,
    required this.music,
    required this.library,
    super.key,
  });

  final Playlist playlist;
  final MusicController music;
  final LibraryController library;

  static Future<void> open(
    BuildContext context, {
    required Playlist playlist,
    required MusicController music,
    required LibraryController library,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistPage(
          playlist: playlist,
          music: music,
          library: library,
        ),
      ),
    );
  }

  Future<void> _play(
    BuildContext context,
    List<TrackItem> list,
    int i, {
    bool resume = false,
  }) async {
    await music.playQueue(list, i, resume: resume);
    if (context.mounted) await NowPlayingScreen.open(context, music);
  }

  Future<void> _shuffle(BuildContext context, List<TrackItem> list) async {
    await music.playShuffled(list);
    if (context.mounted) await NowPlayingScreen.open(context, music);
  }

  Future<void> _onMenu(BuildContext context, _PlaylistAction action) async {
    switch (action) {
      case _PlaylistAction.export:
      case _PlaylistAction.share:
        final share = action == _PlaylistAction.share;
        final messenger = ScaffoldMessenger.of(context);
        final text = M3uExport.build(library.tracksByIds(playlist.tracks));
        final ok = await MediaService.savePlaylist(
          playlist.name,
          text,
          share: share,
        );
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? (share ? 'Playlist shared' : 'Playlist saved to Downloads')
                        .tr
                    : 'Could not export the playlist'.tr,
              ),
            ),
          );
      case _PlaylistAction.rename:
        final name = await askName(
          context,
          title: 'Rename playlist',
          initial: playlist.name,
        );
        if (name != null) music.data.rename(playlist, name);
      case _PlaylistAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete playlist?'),
            content: Text(playlist.name),
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
        music.data.delete(playlist);
        if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([music, music.data, library]),
      builder: (context, _) {
        final list = library.tracksByIds(playlist.tracks);
        return SubPage(
          title: playlist.name,
          music: music,
          actions: [
            PopupMenuButton<_PlaylistAction>(
              onSelected: (action) => _onMenu(context, action),
              itemBuilder: (_) => const <PopupMenuEntry<_PlaylistAction>>[
                PopupMenuItem<_PlaylistAction>(
                  value: _PlaylistAction.export,
                  child: Text('Export'),
                ),
                PopupMenuItem<_PlaylistAction>(
                  value: _PlaylistAction.share,
                  child: Text('Share'),
                ),
                PopupMenuItem<_PlaylistAction>(
                  value: _PlaylistAction.rename,
                  child: Text('Rename'),
                ),
                PopupMenuItem<_PlaylistAction>(
                  value: _PlaylistAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
          child: PageFrame(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'Empty playlist. Add songs from the song menu.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    spacing: AppSpacing.sm,
                    children: [
                      Row(
                        spacing: AppSpacing.sm,
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Play'),
                              onPressed: () => _play(context, list, 0),
                            ),
                          ),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              icon: const Icon(Icons.shuffle_rounded),
                              label: const Text('Shuffle'),
                              onPressed: () => _shuffle(context, list),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: list.length,
                          onReorderItem: (from, to) {
                            music.data.move(
                              playlist,
                              playlist.tracks.indexOf(list[from].id),
                              playlist.tracks.indexOf(list[to].id),
                            );
                          },
                          itemBuilder: (context, i) {
                            final item = list[i];
                            return Row(
                              key: ValueKey<int>(item.id),
                              children: [
                                Expanded(
                                  child: TrackTile(
                                    track: item,
                                    current: music.track == item,
                                    playing: music.playing,
                                    onTap: () => _play(
                                      context,
                                      list,
                                      i,
                                      resume: true,
                                    ),
                                    onLongPress: () => showTrackActions(
                                      context,
                                      music,
                                      item,
                                      onRemove: () => music.data
                                          .removeFrom(playlist, item.id),
                                    ),
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Padding(
                                    padding: EdgeInsets.all(AppSpacing.sm),
                                    child: Icon(Icons.drag_handle_rounded),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
