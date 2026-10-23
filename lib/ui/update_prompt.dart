import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/app_info.dart';
import 'package:papuy/core/update_checker.dart';
import 'package:papuy/core/update_installer.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/system_service.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/theme/app_spacing.dart';

abstract class UpdatePrompt {
  static const Duration _permissionHint = Duration(seconds: 6);

  static bool _started = false;

  static void run(BuildContext context, AppSettings settings) {
    if (_started || !settings.checkUpdates) return;
    _started = true;
    unawaited(_check(context));
  }

  static Future<void> _check(BuildContext context) async {
    final info = await UpdateChecker.check();
    if (info == null) {
      unawaited(UpdateDownload.cleanup());
      return;
    }
    if (!context.mounted) return;
    final download = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update available'),
        content: Text('Version ${info.version} is available. You have ${AppInfo.version}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (download != true || !context.mounted) return;
    if (info.url.toLowerCase().endsWith('.apk')) {
      await _downloadAndInstall(context, info);
    } else {
      await _openInBrowser(info.url);
    }
  }

  static Future<void> _openInBrowser(String url) async {
    try {
      await SystemService.openUrl(url);
    } on Object {
      return;
    }
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    UpdateInfo info,
  ) async {
    final progress = ValueNotifier<double?>(null);
    final download = UpdateDownload();
    var dialogOpen = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _DownloadDialog(
          progress: progress,
          onCancel: () {
            download.cancel();
            Navigator.of(dialogContext).pop();
          },
        ),
      ).then((_) => dialogOpen = false),
    );

    String? path;
    try {
      path = await download.run(
        info.url,
        onProgress: (value) => progress.value = value,
      );
    } on UpdateCancelled {
      return;
    } on Object {
      path = null;
    } finally {
      if (dialogOpen && context.mounted) Navigator.of(context).pop();
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't download the update. Opening your browser instead."),
        ),
      );
      await _openInBrowser(info.url);
      return;
    }
    try {
      final opened = await SystemService.installApk(path);
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Allow ${AppInfo.name} to install apps, then come back to continue.',
            ),
            duration: _permissionHint,
          ),
        );
      }
    } on Object {
      await _openInBrowser(info.url);
    }
  }
}

class _DownloadDialog extends StatelessWidget {
  const _DownloadDialog({required this.progress, required this.onCancel});

  final ValueListenable<double?> progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Downloading update…'),
        content: ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              LinearProgressIndicator(value: value),
              if (value != null) Text('${(value * 100).round()}%'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ],
      ),
    );
  }
}
