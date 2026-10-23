import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/settings/aspect_mode.dart';
import 'package:papuy/settings/orientation_mode.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/details_dialog.dart';
import 'package:papuy/ui/widgets/choice_sheet.dart';
import 'package:papuy/ui/widgets/sleep_picker.dart';

enum _MenuAction {
  repeat,
  aspect,
  orientation,
  loop,
  sleep,
  mute,
  screenshot,
  info,
}

Future<void> showPlayerMenu(
  BuildContext context,
  PlayerController controller,
) async {
  controller.cancelHide();
  final loopValue = controller.markA == null
      ? 'Set A'
      : (controller.markB == null ? 'Set B' : 'Clear');
  final action = await showModalBottomSheet<_MenuAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      void pick(_MenuAction choice) => Navigator.of(sheetContext).pop(choice);
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 560 ? 3 : 2;
              const gap = AppSpacing.sm;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              final tiles = <Widget>[
                _MenuTile(
                  icon: Icons.repeat_rounded,
                  label: 'Repeat',
                  value: controller.repeat.label,
                  onTap: () => pick(_MenuAction.repeat),
                ),
                _MenuTile(
                  icon: Icons.aspect_ratio_rounded,
                  label: 'Aspect ratio',
                  value: controller.aspect.label,
                  onTap: () => pick(_MenuAction.aspect),
                ),
                _MenuTile(
                  icon: Icons.screen_rotation_rounded,
                  label: 'Orientation',
                  value: controller.orientation.label,
                  onTap: () => pick(_MenuAction.orientation),
                ),
                _MenuTile(
                  icon: Icons.loop_rounded,
                  label: 'Repeat A–B',
                  value: loopValue,
                  active: controller.markA != null,
                  onTap: () => pick(_MenuAction.loop),
                ),
                _MenuTile(
                  icon: Icons.bedtime_outlined,
                  label: 'Sleep timer',
                  value: controller.sleepAt == null ? 'Off' : 'On',
                  active: controller.sleepAt != null,
                  onTap: () => pick(_MenuAction.sleep),
                ),
                _MenuTile(
                  icon: controller.muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  label: 'Sound',
                  value: controller.muted ? 'Muted' : 'On',
                  active: controller.muted,
                  onTap: () => pick(_MenuAction.mute),
                ),
                _MenuTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Screenshot',
                  onTap: () => pick(_MenuAction.screenshot),
                ),
                _MenuTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Video info',
                  onTap: () => pick(_MenuAction.info),
                ),
              ];
              return SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final tile in tiles) SizedBox(width: width, child: tile),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
  if (!context.mounted) return;
  switch (action) {
    case null:
      break;
    case _MenuAction.repeat:
      controller.cycleRepeat();
    case _MenuAction.aspect:
      final picked = await showChoices<AspectMode>(
        context,
        title: 'Aspect ratio',
        value: controller.aspect,
        options: <AspectMode, String>{
          for (final mode in AspectMode.values) mode: mode.label,
        },
      );
      if (picked != null) controller.setAspect(picked);
    case _MenuAction.orientation:
      final picked = await showChoices<OrientationMode>(
        context,
        title: 'Orientation',
        value: controller.orientation,
        options: <OrientationMode, String>{
          for (final mode in OrientationMode.values) mode: mode.label,
        },
      );
      if (picked != null) controller.setOrientation(picked);
    case _MenuAction.loop:
      controller.markLoop();
    case _MenuAction.sleep:
      final picked = await pickSleepMinutes(context);
      if (picked != null) controller.setSleepTimer(picked);
    case _MenuAction.mute:
      controller.toggleMute();
    case _MenuAction.screenshot:
      await controller.screenshot();
    case _MenuAction.info:
      await showDetailsDialog(
        context,
        title: 'Video info',
        rows: <String, String>{
          'Name': controller.video.name,
          'Resolution':
              '${controller.displayWidth}×${controller.displayHeight}',
          'Duration': formatDuration(
            Duration(milliseconds: controller.durationMs),
          ),
          if (controller.video.sizeBytes > 0) 'File': controller.video.info,
          'Source': controller.video.uri,
        },
      );
  }
  controller.armHide();
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool active;
  final VoidCallback onTap;

  static const double _iconSize = 20;
  static const double _labelSize = 12;
  static const double _valueSize = 10.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = active ? scheme.primary : scheme.onSurfaceVariant;
    return Material(
      color: active ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Icon(icon, size: _iconSize, color: tint),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: _labelSize,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (value != null)
                      Text(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: _valueSize,
                          color: tint,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
