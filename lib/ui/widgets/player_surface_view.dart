import 'package:flutter/material.dart';
import 'package:papuy/player/player_controller.dart';
import 'package:papuy/settings/aspect_mode.dart';

class PlayerSurfaceView extends StatelessWidget {
  const PlayerSurfaceView({required this.controller, super.key});

  final PlayerController controller;

  static const double _fallbackWidth = 16;
  static const double _fallbackHeight = 9;

  @override
  Widget build(BuildContext context) {
    final info = controller.info;
    if (info == null) return const SizedBox.shrink();
    final turned = controller.rotation % 180 != 0;
    final rawWidth = (controller.videoWidth > 0
            ? controller.videoWidth
            : info.width)
        .toDouble();
    final rawHeight = (controller.videoHeight > 0
            ? controller.videoHeight
            : info.height)
        .toDouble();
    final pixelRatio = controller.pixelRatio > 0 ? controller.pixelRatio : 1;
    final width = (turned ? rawHeight : rawWidth) * pixelRatio;
    final height = turned ? rawWidth : rawHeight;

    Widget texture = Texture(textureId: info.texture);
    if (controller.rotation != 0) {
      texture = RotatedBox(
        quarterTurns: (controller.rotation ~/ 90) % 4,
        child: texture,
      );
    }
    final natural = height > 0 ? width / height : 16 / 9;
    final fixed = controller.aspect.ratio;
    if (fixed != null) {
      return Center(child: AspectRatio(aspectRatio: fixed, child: texture));
    }
    switch (controller.aspect) {
      case AspectMode.fill:
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: width > 0 ? width : _fallbackWidth,
              height: height > 0 ? height : _fallbackHeight,
              child: texture,
            ),
          ),
        );
      case AspectMode.stretch:
        return SizedBox.expand(child: texture);
      case AspectMode.fit ||
            AspectMode.wide ||
            AspectMode.standard ||
            AspectMode.cinema:
        return Center(child: AspectRatio(aspectRatio: natural, child: texture));
    }
  }
}
