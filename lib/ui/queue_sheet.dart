import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/theme/app_motion.dart';
import 'package:papuy/ui/widgets/track_tile.dart';

Future<void> showQueueSheet(BuildContext context, MusicController music) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return ListenableBuilder(
            listenable: music,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Queue · ${music.queue.length}',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      scrollController: controller,
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: music.queue.length,
                      proxyDecorator: (child, index, animation) {
                        final lift = Curves.easeOut.transform(animation.value);
                        return Transform.scale(
                          scale: 1 + 0.03 * lift,
                          child: Material(
                            elevation: 8 * lift,
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          ),
                        );
                      },
                      onReorderItem: (from, to) =>
                          music.moveInQueue(from, to > from ? to - 1 : to),
                      itemBuilder: (context, i) {
                        final item = music.queue[i];
                        final current = i == music.index;
                        var occurrence = 0;
                        for (var k = 0; k < i; k++) {
                          if (music.queue[k].id == item.id) occurrence++;
                        }
                        final row = AnimatedContainer(
                          duration: AppMotion.d(280),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: current
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TrackTile(
                                  track: item,
                                  current: current,
                                  playing: music.playing,
                                  showAlbum: false,
                                  onTap: () => music.jumpTo(i),
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.drag_handle_rounded),
                                ),
                              ),
                            ],
                          ),
                        );
                        final key = ValueKey<String>('${item.id}#$occurrence');
                        if (current) return KeyedSubtree(key: key, child: row);
                        return Dismissible(
                          key: key,
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => music.removeAt(i),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          child: row,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
