import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/theme/app_theme.dart';

class PlayerTopBar extends StatelessWidget {
  const PlayerTopBar({
    required this.controller,
    required this.onMore,
    super.key,
  });

  final PlayerController controller;
  final VoidCallback onMore;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<StatusColors>()!;
    final onVideo = theme.textTheme.bodyMedium?.copyWith(color: status.onScrim);
    final clock = controller.settings.showClock
        ? TimeOfDay.now().format(context)
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            status.scrim.withValues(alpha: 0.67),
            status.scrim.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back'.tr,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                controller.library.title(controller.video),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: onVideo,
              ),
            ),
            if (controller.markA != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  controller.markB == null ? 'A' : 'A–B',
                  style: onVideo,
                ),
              ),
            if (controller.sleepAt != null)
              Icon(
                Icons.bedtime_outlined,
                size: _iconSize,
                color: status.onScrim,
              ),
            if (clock != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(clock, style: onVideo),
              ),
            IconButton(
              tooltip: 'Floating window'.tr,
              icon: const Icon(Icons.picture_in_picture_alt_rounded),
              onPressed: controller.enterPip,
            ),
            IconButton(
              tooltip: 'More'.tr,
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}
