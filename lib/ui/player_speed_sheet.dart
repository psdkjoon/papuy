import 'package:flutter/material.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/ui/widgets/choice_sheet.dart';

const Map<int, String> _speeds = <int, String>{
  25: '0.25×',
  50: '0.5×',
  75: '0.75×',
  100: '1×',
  125: '1.25×',
  150: '1.5×',
  175: '1.75×',
  200: '2×',
  300: '3×',
  400: '4×',
};

Future<void> showSpeedSheet(
  BuildContext context,
  PlayerController controller,
) async {
  controller.cancelHide();
  final picked = await showChoices<int>(
    context,
    title: 'Speed',
    value: (controller.speed * 100).round(),
    options: _speeds,
  );
  if (picked != null) controller.chooseSpeed(picked / 100);
  controller.armHide();
}
