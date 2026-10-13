import 'package:flutter/material.dart';
import 'package:papuy/theme/app_motion.dart';

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const int _limit = 12;
  static const int _stagger = 40;
  static const int _length = 320;

  late final bool _animated = AppMotion.enabled && widget.index < _limit;
  late final int _delay = widget.index.clamp(0, _limit) * _stagger;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _animated ? _length + _delay : 1),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _animated ? _delay / (_length + _delay) : 0,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (_animated) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animated) return widget.child;
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
