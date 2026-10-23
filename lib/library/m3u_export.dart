import 'package:papuy/library/track_item.dart';

abstract class M3uExport {
  static String build(List<TrackItem> tracks) {
    final out = StringBuffer('#EXTM3U\n');
    for (final track in tracks) {
      final seconds = (track.durationMs / 1000).round();
      final label = track.artist.isEmpty
          ? track.title
          : '${track.artist} - ${track.title}';
      out
        ..write('#EXTINF:$seconds,${label.replaceAll(RegExp(r'[\r\n]+'), ' ')}\n')
        ..write('${track.path.isEmpty ? track.name : track.path}\n');
    }
    return out.toString();
  }
}
