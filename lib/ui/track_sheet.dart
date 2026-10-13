import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/theme/app_spacing.dart';

Future<void> showTrackSheet(
  BuildContext context,
  PlayerController controller,
) async {
  if (controller.info == null) return;
  controller.cancelHide();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TrackSheet(controller: controller),
  );
  controller.armHide();
}

class _TrackSheet extends StatelessWidget {
  const _TrackSheet({required this.controller});

  final PlayerController controller;

  Widget _header(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxs,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _item(ThemeData theme, String label, bool selected, VoidCallback onTap) {
    return ListTile(
      dense: true,
      title: Text(label),
      selected: selected,
      trailing: selected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final audio = controller.tracks.where((t) => t.type == 'audio');
        final text = controller.tracks.where((t) => t.type == 'text').toList();
        final video = controller.tracks.where((t) => t.type == 'video').toList();
        final textOn = text.any((t) => t.selected);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(theme, 'Audio'),
                if (audio.isEmpty)
                  const ListTile(dense: true, title: Text('Default')),
                for (final track in audio)
                  _item(
                    theme,
                    track.label,
                    track.selected,
                    () => controller.selectTrack(track),
                  ),
                _header(theme, 'Subtitles'),
                SwitchListTile(
                  dense: true,
                  title: const Text('Show subtitles'),
                  value: controller.subtitlesVisible,
                  onChanged: (value) =>
                      controller.setSubtitlesVisible(visible: value),
                ),
                if (text.isNotEmpty)
                  _item(
                    theme,
                    'Off',
                    !textOn,
                    controller.disableSubtitleTrack,
                  ),
                for (final track in text)
                  _item(
                    theme,
                    track.label,
                    track.selected,
                    () => controller.selectTrack(track),
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.add_rounded),
                  title: Text(
                    controller.cues.isEmpty
                        ? 'Load .srt file…'
                        : 'Load another .srt file…',
                  ),
                  onTap: controller.loadSubtitleFile,
                ),
                if (controller.cues.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(
                      'Delay ${(controller.subtitleDelayMs / 1000).toStringAsFixed(1)}s',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded),
                          onPressed: () => controller.shiftSubtitles(-100),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded),
                          onPressed: () => controller.shiftSubtitles(100),
                        ),
                      ],
                    ),
                  ),
                if (video.length > 1) ...[
                  _header(theme, 'Quality'),
                  _item(
                    theme,
                    'Auto',
                    controller.videoAuto,
                    controller.selectAutoQuality,
                  ),
                  for (final track in video)
                    _item(
                      theme,
                      track.label,
                      !controller.videoAuto && track.selected,
                      () => controller.selectTrack(track),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
