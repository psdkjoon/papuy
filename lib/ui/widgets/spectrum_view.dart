import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:papuy/platform/player_service.dart';

class SpectrumView extends StatefulWidget {
  const SpectrumView({
    required this.active,
    this.height = 72,
    super.key,
  });

  final bool active;
  final double height;

  @override
  State<SpectrumView> createState() => _SpectrumViewState();
}

class _SpectrumViewState extends State<SpectrumView>
    with SingleTickerProviderStateMixin {
  static const int _bands = 40;
  static const Duration _fetchEvery = Duration(milliseconds: 28);
  static const double _fall = 1.6;
  static const double _attack = 0.6;

  late final Ticker _ticker;
  final List<double> _levels = List<double>.filled(_bands, 0);
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  Uint8List? _raw;
  Duration _last = Duration.zero;
  Duration _lastFetch = Duration.zero;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(SpectrumView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ticker.isActive) {
      _last = Duration.zero;
      _lastFetch = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    _fetching = true;
    final data = await PlayerService.bands();
    _fetching = false;
    if (mounted) _raw = data;
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = elapsed;
    if (widget.active && !_fetching && elapsed - _lastFetch >= _fetchEvery) {
      _lastFetch = elapsed;
      _fetch();
    }
    final raw = widget.active ? _raw : null;
    var peak = 0.0;
    for (var i = 0; i < _bands; i++) {
      final target = raw != null && i < raw.length ? raw[i] / 255.0 : 0.0;
      var level = _levels[i];
      if (target > level) {
        level += (target - level) * _attack;
      } else {
        level = level - dt * _fall;
        if (level < target) level = target;
      }
      if (level < 0) level = 0;
      _levels[i] = level;
      if (level > peak) peak = level;
    }
    _repaint.value++;
    if (!widget.active && peak < 0.004) {
      for (var i = 0; i < _bands; i++) {
        _levels[i] = 0;
      }
      _repaint.value++;
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SpectrumPainter(
            levels: _levels,
            low: scheme.primary,
            high: scheme.tertiary,
            idle: scheme.onSurfaceVariant.withValues(alpha: 0.25),
            repaint: _repaint,
          ),
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter({
    required this.levels,
    required this.low,
    required this.high,
    required this.idle,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<double> levels;
  final Color low;
  final Color high;
  final Color idle;

  static const int _side = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final bands = levels.length;
    const total = _side * 2;
    const gap = 3.0;
    final barWidth = (size.width - gap * (total - 1)) / total;
    if (barWidth <= 0) return;
    final radius = Radius.circular(barWidth / 2);
    final shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [low, high],
    ).createShader(Offset.zero & size);
    final fill = Paint()..shader = shader;
    final rest = Paint()..color = idle;
    for (var position = 0; position < total; position++) {
      final distance = position < _side ? _side - 1 - position : position - _side;
      final band = (distance * (bands - 1) / (_side - 1)).round();
      final level = levels[band].clamp(0.0, 1.0).toDouble();
      final left = position * (barWidth + gap);
      final height = barWidth + (size.height - barWidth) * level;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - height, barWidth, height),
        radius,
      );
      canvas.drawRRect(rect, level < 0.02 ? rest : fill);
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter oldDelegate) =>
      oldDelegate.low != low ||
      oldDelegate.high != high ||
      oldDelegate.idle != idle;
}
