import 'package:flutter/material.dart';

enum SubtitleColor {
  white('White', Colors.white),
  yellow('Yellow', Color(0xFFFFEB3B)),
  cyan('Cyan', Color(0xFF4DD0E1)),
  green('Green', Color(0xFF9CCC65));

  const SubtitleColor(this.label, this.color);

  final String label;
  final Color color;
}
