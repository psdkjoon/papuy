import 'package:papuy/library/track_item.dart';

class M3uResult {
  const M3uResult({required this.ids, required this.total});

  final List<int> ids;
  final int total;
}

abstract class M3uImport {
  static String playlistName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    return base.trim();
  }

  static String _base(String path) {
    var value = path.trim();
    if (value.startsWith('file://')) value = value.substring(7);
    final cut = value.lastIndexOf(RegExp(r'[/\\]'));
    if (cut >= 0) value = value.substring(cut + 1);
    try {
      value = Uri.decodeComponent(value);
    } on Object {
      return value.toLowerCase();
    }
    return value.toLowerCase();
  }

  static String _noExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static M3uResult parse(String text, List<TrackItem> library) {
    final byName = <String, TrackItem>{};
    final byBase = <String, TrackItem>{};
    final byTitle = <String, TrackItem>{};
    for (final track in library) {
      final name = track.name.toLowerCase();
      byName.putIfAbsent(name, () => track);
      byBase.putIfAbsent(_noExtension(name), () => track);
      byTitle.putIfAbsent(track.title.toLowerCase(), () => track);
      if (track.artist.isNotEmpty) {
        byTitle.putIfAbsent(
          '${track.artist} - ${track.title}'.toLowerCase(),
          () => track,
        );
      }
    }
    final lines = text.replaceFirst('﻿', '').split(RegExp(r'\r?\n'));
    final ids = <int>[];
    final seen = <int>{};
    var total = 0;
    String? info;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) {
        if (line.toUpperCase().startsWith('#EXTINF')) {
          final comma = line.indexOf(',');
          info = comma >= 0 ? line.substring(comma + 1).trim() : null;
        }
        continue;
      }
      total++;
      final file = _base(line);
      var found = byName[file] ?? byBase[_noExtension(file)];
      if (found == null && info != null && info.isNotEmpty) {
        final key = info.toLowerCase();
        found = byTitle[key];
        if (found == null) {
          final split = key.indexOf(' - ');
          if (split >= 0) found = byTitle[key.substring(split + 3)];
        }
      }
      info = null;
      if (found != null && seen.add(found.id)) ids.add(found.id);
    }
    return M3uResult(ids: ids, total: total);
  }
}
