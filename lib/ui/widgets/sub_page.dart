import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/localization/localization.dart';

class SubPage extends StatelessWidget {
  const SubPage({
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubPage(title: title, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(top: false, child: child),
    );
  }
}
