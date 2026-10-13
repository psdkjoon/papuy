import 'package:flutter/material.dart';
import 'package:papuy/theme/app_motion.dart';

class SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!AppMotion.enabled) return child;
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final from = Offset(rtl ? -0.08 : 0.08, 0);
    final to = Offset(rtl ? 0.04 : -0.04, 0);
    return SlideTransition(
      position: Tween<Offset>(begin: Offset.zero, end: to).animate(exit),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.6).animate(exit),
        child: SlideTransition(
          position: Tween<Offset>(begin: from, end: Offset.zero).animate(enter),
          child: FadeTransition(opacity: enter, child: child),
        ),
      ),
    );
  }
}

class RiseRoute<T> extends PageRouteBuilder<T> {
  RiseRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: AppMotion.d(380),
          reverseTransitionDuration: AppMotion.d(300),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.3, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
}
