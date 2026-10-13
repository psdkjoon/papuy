import 'package:flutter/material.dart';

abstract class AppIcon {
  static const String logoMocha = 'assets/icons/logo_mocha.png';
  static const String logoLatte = 'assets/icons/logo_latte.png';

  static String logo(Brightness brightness) =>
      brightness == Brightness.dark ? logoMocha : logoLatte;
}
