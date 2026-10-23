import 'package:flutter/services.dart';

abstract class SystemService {
  static const _channel = MethodChannel('papuy/system');

  static Future<void> _fire(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      return;
    }
  }

  static Future<void> openUrl(String url) =>
      _channel.invokeMethod<void>('openUrl', {'url': url});

  static Future<bool> installApk(String path) async {
    final status =
        await _channel.invokeMethod<String>('installApk', {'path': path});
    return status == 'installing';
  }

  static Future<String?> androidAbi() async {
    try {
      return await _channel.invokeMethod<String>('abi');
    } on PlatformException {
      return null;
    }
  }

  static Future<void> notify(String title, String body) =>
      _fire('notify', {'title': title, 'body': body});

  static Future<void> closeQuick() => _fire('closeQuick');

  static Future<void> openFull() => _fire('openFull');

  static Future<void> setQuickPlay({required bool on}) =>
      _fire('setQuickPlay', {'on': on});

  static Future<void> requestNotificationPermission() =>
      _fire('requestNotifications');

  static Future<void> requestBackgroundAccess() =>
      _fire('requestBackgroundAccess');
}
