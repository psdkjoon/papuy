import 'dart:typed_data';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:papuy/library/art_cache.dart';
import 'package:papuy/library/track_item.dart';
import 'package:papuy/localization/localization.dart';

class TrackArt extends StatelessWidget {
  const TrackArt({
    required this.track,
    this.size,
    this.radius = 12,
    this.pixels = 256,
    super.key,
  });

  final TrackItem track;
  final double? size;
  final double radius;
  final int pixels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tints = <Color>[scheme.primary, scheme.secondary, scheme.tertiary];
    final first = tints[track.albumId.abs() % tints.length];
    final second = tints[(track.albumId.abs() + 1) % tints.length];
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: scheme.surfaceContainerHighest),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  first.withValues(alpha: 0.5),
                  second.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.4,
              heightFactor: 0.4,
              child: FittedBox(
                child: Icon(
                  Icons.music_note_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          FutureBuilder<Uint8List?>(
            future: ArtCache.of(track, size: pixels),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes == null) return const SizedBox.shrink();
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              );
            },
          ),
        ],
      ),
    );
    final fixed = size;
    if (fixed == null) return AspectRatio(aspectRatio: 1, child: art);
    return SizedBox(width: fixed, height: fixed, child: art);
  }
}
