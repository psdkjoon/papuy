import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/theme/app_theme.dart';

class SubtitleOverlay extends StatelessWidget {
  const SubtitleOverlay({
    required this.text,
    required this.settings,
    super.key,
  });

  final String? text;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final cue = text;
    if (cue == null || cue.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final boxed = settings.subtitleBox;
    final vertical = settings.subtitlePos / 100 * 2 - 1;
    return IgnorePointer(
      child: Align(
        alignment: Alignment(0, vertical),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: boxed
                ? theme.extension<StatusColors>()!.scrim.withValues(alpha: 0.65)
                : null,
            borderRadius: BorderRadius.circular(AppRadius.tile / 4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs / 2,
            ),
            child: Text(
              cue,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: settings.subtitleColor.color,
                fontSize: settings.subtitleSize.toDouble(),
                shadows: boxed
                    ? null
                    : const [Shadow(blurRadius: 4), Shadow(blurRadius: 8)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
