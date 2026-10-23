import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/theme/app_spacing.dart';

class PlayerCenterControls extends StatelessWidget {
  const PlayerCenterControls({required this.controller, super.key});

  final PlayerController controller;

  static const double _skipSize = 38;
  static const double _playSize = 44;
  static const double _playButton = 72;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xl,
      children: [
        IconButton(
          tooltip: 'Previous'.tr,
          iconSize: _skipSize,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: controller.hasPrevious
              ? () => controller.go(controller.index - 1)
              : null,
        ),
        IconButton.filled(
          tooltip: controller.playing ? 'Pause'.tr : 'Play'.tr,
          iconSize: _playSize,
          style: IconButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            fixedSize: const Size(_playButton, _playButton),
          ),
          icon: Icon(
            controller.playing
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
          ),
          onPressed: controller.togglePlay,
        ),
        IconButton(
          tooltip: 'Next'.tr,
          iconSize: _skipSize,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: controller.hasNext
              ? () => controller.go(controller.index + 1)
              : null,
        ),
      ],
    );
  }
}
