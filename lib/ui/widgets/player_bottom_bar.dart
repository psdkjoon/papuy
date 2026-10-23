import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/core/format_duration.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/settings/loop_mode.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/theme/app_theme.dart';

class PlayerBottomBar extends StatelessWidget {
  const PlayerBottomBar({
    required this.controller,
    required this.onSpeed,
    required this.onTracks,
    super.key,
  });

  final PlayerController controller;
  final VoidCallback onSpeed;
  final VoidCallback onTracks;

  Widget _button(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).extension<StatusColors>()!.onScrim,
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = theme.textTheme.labelMedium?.copyWith(
      color: theme.extension<StatusColors>()!.onScrim,
    );
    final total = (controller.durationMs > 0 ? controller.durationMs : 1) / 1000.0;
    final current = (controller.position.inMilliseconds / 1000.0)
        .clamp(0.0, total)
        .toDouble();
    final remaining = controller.settings.showRemaining;
    final left = Duration(
      milliseconds: (controller.durationMs - controller.position.inMilliseconds)
          .clamp(0, controller.durationMs)
          .toInt(),
    );
    final repeat = controller.repeat;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xAA000000), Color(0x00000000)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(formatDuration(controller.position), style: label),
                  Expanded(
                    child: Slider(
                      value: current,
                      max: total,
                      onChangeStart: (_) => controller.startScrub(),
                      onChanged: (value) => controller.previewScrub(
                        Duration(milliseconds: (value * 1000).round()),
                      ),
                      onChangeEnd: (value) => controller.endScrub(
                        Duration(milliseconds: (value * 1000).round()),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.settings.showRemaining = !remaining,
                    child: Text(
                      remaining
                          ? '−${formatDuration(left)}'
                          : formatDuration(
                              Duration(milliseconds: controller.durationMs),
                            ),
                      style: label,
                    ),
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _button(
                      context,
                      Icons.aspect_ratio_rounded,
                      controller.aspect.label,
                      controller.cycleAspect,
                    ),
                    _button(
                      context,
                      Icons.speed_rounded,
                      '${controller.speedLabel}×',
                      onSpeed,
                    ),
                    _button(
                      context,
                      repeat == LoopMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      repeat == LoopMode.off ? 'Repeat' : repeat.label,
                      controller.cycleRepeat,
                    ),
                    _button(
                      context,
                      Icons.screen_rotation_rounded,
                      'Rotate',
                      controller.cycleOrientation,
                    ),
                    _button(
                      context,
                      Icons.lock_outline_rounded,
                      'Lock',
                      controller.toggleLock,
                    ),
                    _button(
                      context,
                      Icons.subtitles_rounded,
                      'Tracks',
                      onTracks,
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
