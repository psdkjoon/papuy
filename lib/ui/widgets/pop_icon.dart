import 'package:flutter/material.dart' hide Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/theme/app_motion.dart';

class PopIcon extends StatelessWidget {
  const PopIcon({required this.icon, required this.color, this.size, super.key});

  final IconData icon;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: AppMotion.d(260),
      builder: (context, value, _) {
        return AnimatedSwitcher(
          duration: AppMotion.d(260),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: RotationTransition(
              turns: Tween<double>(begin: -0.12, end: 0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
          ),
          child: Icon(
            icon,
            key: ValueKey<IconData>(icon),
            size: size,
            color: value ?? color,
          ),
        );
      },
    );
  }
}
