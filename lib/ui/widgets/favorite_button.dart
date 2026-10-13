import 'dart:math' as math;

import 'package:flutter/material.dart' hide Icon;
import 'package:papuy/localization/localization.dart';
import 'package:papuy/theme/app_motion.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    required this.favorite,
    required this.onPressed,
    this.size = 24,
    super.key,
  });

  final bool favorite;
  final VoidCallback onPressed;
  final double size;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  static const Color _heart = Color(0xFFEF4A6A);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.d(650),
  );

  static final Animatable<double> _pop = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.65), weight: 14),
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.65, end: 1.45)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 36,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.45, end: 1)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 50,
    ),
  ]);

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.favorite && !oldWidget.favorite) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final box = widget.size * 2.4;
    return Tooltip(
      message: 'Favorites'.tr,
      child: InkResponse(
        onTap: widget.onPressed,
        radius: widget.size * 1.2,
        child: SizedBox(
          width: box,
          height: box,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (_controller.isAnimating)
                    CustomPaint(
                      size: Size.square(box),
                      painter: _BurstPainter(progress: t, color: _heart),
                    ),
                  Transform.scale(
                    scale: _controller.isAnimating ? _pop.transform(t) : 1,
                    child: Icon(
                      widget.favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: widget.size,
                      color: widget.favorite ? _heart : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const int _sparks = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0).toDouble();
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * fade
      ..color = color.withValues(alpha: 0.55 * fade);
    canvas.drawCircle(center, size.width * (0.18 + 0.3 * eased), ring);
    final spark = Paint()..color = color.withValues(alpha: fade);
    final reach = size.width * (0.22 + 0.26 * eased);
    for (var i = 0; i < _sparks; i++) {
      final angle = 2 * math.pi * i / _sparks + math.pi / 8;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * reach;
      canvas.drawCircle(point, (i.isEven ? 3.2 : 2.2) * fade, spark);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
