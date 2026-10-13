import 'package:papuy/player/track_option.dart';

class PlayerInfo {
  const PlayerInfo({
    required this.texture,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.ratio,
    required this.rotation,
    required this.tracks,
  });

  factory PlayerInfo.fromMap(Map<String, Object?> map) {
    return PlayerInfo(
      texture: (map['texture'] as num?)?.toInt() ?? 0,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      ratio: (map['ratio'] as num?)?.toDouble() ?? 1.0,
      rotation: (map['rotation'] as num?)?.toInt() ?? 0,
      tracks: TrackOption.parseList(map['tracks']),
    );
  }

  final int texture;
  final int durationMs;
  final int width;
  final int height;
  final double ratio;
  final int rotation;
  final List<TrackOption> tracks;
}

class PlayerSnapshot {
  const PlayerSnapshot({
    required this.positionMs,
    required this.playing,
    required this.buffering,
    required this.durationMs,
  });

  final int positionMs;
  final bool playing;
  final bool buffering;
  final int durationMs;
}
