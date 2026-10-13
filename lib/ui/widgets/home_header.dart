import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/theme/app_spacing.dart';
import 'package:papuy/ui/about_screen.dart';
import 'package:papuy/ui/settings_screen.dart';
import 'package:papuy/ui/widgets/sub_page.dart';

class ModeSwitch extends StatelessWidget {
  const ModeSwitch({required this.mode, super.key});

  final ValueNotifier<int> mode;

  static const List<String> _labels = <String>['Videos', 'Music'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: mode,
      builder: (context, current, _) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
          spacing: AppSpacing.md,
          children: [
            for (var i = 0; i < _labels.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.tile),
                onTap: () => mode.value = i,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    _labels[i],
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: i == current
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
          ],
          ),
        );
      },
    );
  }
}

abstract class HomeHeader {
  static List<Widget> trailing(
    BuildContext context, {
    required AppSettings settings,
    required LibraryController library,
  }) {
    return [
      IconButton(
        tooltip: 'Settings'.tr,
        icon: const Icon(Icons.tune_rounded),
        onPressed: () => SubPage.open(
          context,
          title: 'Settings',
          child: SettingsScreen(settings: settings, library: library),
        ),
      ),
      IconButton(
        tooltip: 'About'.tr,
        icon: const Icon(Icons.info_outline_rounded),
        onPressed: () => SubPage.open(
          context,
          title: 'About',
          child: const AboutScreen(),
        ),
      ),
    ];
  }
}
