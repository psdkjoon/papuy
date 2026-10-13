import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:papuy/app_info.dart';
import 'package:papuy/library/library_controller.dart';
import 'package:papuy/localization/localization.dart';
import 'package:papuy/platform/media_service.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/settings/app_settings.dart';
import 'package:papuy/theme/app_theme.dart';
import 'package:papuy/ui/app_shell.dart';
import 'package:papuy/ui/quick/quick_shell.dart';

class PapuyApp extends StatelessWidget {
  const PapuyApp({
    required this.settings,
    required this.library,
    required this.music,
    super.key,
  });

  final AppSettings settings;
  final LibraryController library;
  final MusicController music;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: AppInfo.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(settings.accent),
          darkTheme: AppTheme.dark(settings.accent),
          themeMode: settings.themeMode,
          scrollBehavior: const _NoScrollbarBehavior(),
          locale: L10n.locale,
          supportedLocales: [
            for (final language in L10n.languages) Locale(language.code),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            final icons = dark ? Brightness.light : Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: icons,
                statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: icons,
                systemNavigationBarContrastEnforced: false,
                systemStatusBarContrastEnforced: false,
              ),
              child: _ScaledView(percent: settings.uiScale, child: child!),
            );
          },
          home: KeyedSubtree(
            key: ValueKey(L10n.code),
            child: ValueListenableBuilder<IncomingVideo?>(
              valueListenable: MediaService.quickRequest,
              builder: (context, request, _) => Stack(
                fit: StackFit.expand,
                children: [
                  Offstage(
                    offstage: request != null,
                    child: AppShell(
                      settings: settings,
                      library: library,
                      music: music,
                    ),
                  ),
                  if (request != null)
                    QuickShell(
                      key: ValueKey(request.uri),
                      request: request,
                      settings: settings,
                      library: library,
                      music: music,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _ScaledView extends StatelessWidget {
  const _ScaledView({required this.percent, required this.child});

  final int percent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scale = percent / 100;
    if (percent == 100) return child;
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth / scale;
        final height = box.maxHeight / scale;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: MediaQuery(
                data: media.copyWith(
                  size: Size(width, height),
                  padding: media.padding / scale,
                  viewPadding: media.viewPadding / scale,
                  viewInsets: media.viewInsets / scale,
                  systemGestureInsets: media.systemGestureInsets / scale,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
