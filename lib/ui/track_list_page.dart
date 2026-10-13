import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/track_item.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/now_playing_screen.dart';
import 'package:papuy/ui/playlist_picker.dart';
import 'package:papuy/ui/track_actions_sheet.dart';
import 'package:papuy/ui/widgets/page_frame.dart';
import 'package:papuy/ui/widgets/track_tile.dart';

class TrackListPage extends StatelessWidget {
  const TrackListPage({
    required this.tracks,
    required this.music,
    this.showAlbum = false,
    super.key,
  });

  final List<TrackItem> Function() tracks;
  final MusicController music;
  final bool showAlbum;

  Future<void> _play(BuildContext context, List<TrackItem> list, int index) async {
    await music.playQueue(list, index);
    if (context.mounted) await NowPlayingScreen.open(context, music);
  }

  Future<void> _shuffle(BuildContext context, List<TrackItem> list) async {
    await music.playShuffled(list);
    if (context.mounted) await NowPlayingScreen.open(context, music);
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      child: ListenableBuilder(
        listenable: Listenable.merge([music, music.data]),
        builder: (context, _) {
          final list = tracks();
          if (list.isEmpty) return const Center(child: Text('No music'));
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Row(
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
                    IconButton.filledTonal(
                      tooltip: 'Add to playlist'.tr,
                      icon: const Icon(Icons.playlist_add_rounded),
                      onPressed: () => showPlaylistPicker(
                        context,
                        music,
                        <int>[for (final item in list) item.id],
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              SliverList.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final item = list[i];
                  return TrackTile(
                    track: item,
                    showAlbum: showAlbum,
                    current: music.track == item,
                    playing: music.playing,
                    onTap: () => _play(context, list, i),
                    onLongPress: () => showTrackActions(context, music, item),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          );
        },
      ),
    );
  }
}
