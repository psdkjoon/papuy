import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/player/music_controller.dart';
import 'package:papuy/ui/widgets/music_dock_view.dart';

class SubPage extends StatelessWidget {
  const SubPage({
    required this.title,
    required this.child,
    required this.music,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final Widget child;
  final MusicController music;
  final List<Widget> actions;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required Widget child,
    required MusicController music,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubPage(title: title, music: music, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: MusicDockView(
        music: music,
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}
