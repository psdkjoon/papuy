import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/theme/app_spacing.dart';

enum VideoMenuAction { sort, stream, refresh }

Future<VideoMenuAction?> showVideoMenu(
  BuildContext context,
  AppSettings settings,
) {
  return showModalBottomSheet<VideoMenuAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            Widget toggle(
              IconData icon,
              String title,
              bool value,
              ValueChanged<bool> onChanged,
            ) {
              return SwitchListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                secondary: Icon(icon, size: 20),
                title: Text(title),
                value: value,
                onChanged: onChanged,
              );
            }

            Widget action(IconData icon, String title, VideoMenuAction value) {
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(icon, size: 20),
                title: Text(title),
                onTap: () => Navigator.of(sheetContext).pop(value),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  toggle(
                    Icons.grid_view_rounded,
                    'Grid view',
                    settings.grid,
                    (value) => settings.grid = value,
                  ),
                  toggle(
                    Icons.folder_outlined,
                    'Group by folder',
                    settings.groupFolders,
                    (value) => settings.groupFolders = value,
                  ),
                  toggle(
                    Icons.swap_vert_rounded,
                    'Reverse order',
                    settings.sortAsc,
                    (value) => settings.sortAsc = value,
                  ),
                  const Divider(height: 1),
                  action(Icons.sort_rounded, 'Sort by…', VideoMenuAction.sort),
                  action(
                    Icons.link_rounded,
                    'Network stream…',
                    VideoMenuAction.stream,
                  ),
                  action(
                    Icons.refresh_rounded,
                    'Refresh',
                    VideoMenuAction.refresh,
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
