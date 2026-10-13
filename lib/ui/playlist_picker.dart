import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/ui/name_dialog.dart';

Future<void> showPlaylistPicker(
  BuildContext context,
  MusicController music,
  List<int> ids,
) {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListenableBuilder(
          listenable: music.data,
          builder: (context, _) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_rounded),
                    title: const Text('New playlist'),
                    onTap: () async {
                      final name = await askName(
                        sheetContext,
                        title: 'New playlist',
                        action: 'Create',
                      );
                      if (name == null) return;
                      final created = music.data.create(name, ids);
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      say('Added to ${created.name}');
                    },
                  ),
                  for (final playlist in music.data.playlists)
                    ListTile(
                      leading: const Icon(Icons.queue_music_rounded),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.tracks.length} songs'),
                      onTap: () {
                        final added = music.data.addAll(playlist, ids);
                        Navigator.of(sheetContext).pop();
                        say(
                          added > 0
                              ? 'Added to ${playlist.name}'
                              : 'Already in ${playlist.name}',
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
