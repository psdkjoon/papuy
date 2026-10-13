import 'package:flutter/material.dart';
import 'package:papuy/theme/app_motion.dart';

class AnimatedPlayIcon extends StatefulWidget {
  const AnimatedPlayIcon({
    required this.playing,
    this.size,
    this.color,
    super.key,
  });

  final bool playing;
  final double? size;
  final Color? color;

  @override
  State<AnimatedPlayIcon> createState() => _AnimatedPlayIconState();
}

class _AnimatedPlayIconState extends State<AnimatedPlayIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.d(260),
    value: widget.playing ? 1 : 0,
  );

  late final Animation<double> _progress =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void didUpdateWidget(AnimatedPlayIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing != oldWidget.playing) {
      if (widget.playing) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      progress: _progress,
      size: widget.size,
      color: widget.color,
    );
  }
}
