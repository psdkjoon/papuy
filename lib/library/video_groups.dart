import 'package:papuy/library/video_item.dart';

Map<String, List<VideoItem>> groupByFolder(List<VideoItem> videos) {
  final map = <String, List<VideoItem>>{};
  for (final video in videos) {
    (map[video.folder] ??= <VideoItem>[]).add(video);
  }
  final keys = map.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return <String, List<VideoItem>>{for (final key in keys) key: map[key]!};
}
