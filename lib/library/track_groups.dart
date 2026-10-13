import 'package:papuy/library/track_item.dart';

class AlbumGroup {
  const AlbumGroup({
    required this.name,
    required this.artist,
    required this.tracks,
  });

  final String name;
  final String artist;
  final List<TrackItem> tracks;

  TrackItem get cover => tracks.first;
}

class ArtistGroup {
  const ArtistGroup({
    required this.name,
    required this.tracks,
    required this.albums,
  });

  final String name;
  final List<TrackItem> tracks;
  final int albums;

  TrackItem get cover => tracks.first;
}

int _compareText(String a, String b) =>
    a.toLowerCase().compareTo(b.toLowerCase());

int _compareInAlbum(TrackItem a, TrackItem b) {
  if (a.number != b.number) return a.number.compareTo(b.number);
  return _compareText(a.title, b.title);
}

List<AlbumGroup> groupByAlbum(List<TrackItem> tracks) {
  final map = <String, List<TrackItem>>{};
  for (final track in tracks) {
    map.putIfAbsent(track.albumId > 0 ? 'a${track.albumId}' : 'n${track.album}', () => <TrackItem>[]).add(track);
  }
  final groups = <AlbumGroup>[
    for (final list in map.values)
      AlbumGroup(
        name: list.first.albumLabel,
        artist: _commonArtist(list),
        tracks: list..sort(_compareInAlbum),
      ),
  ]..sort((a, b) => _compareText(a.name, b.name));
  return groups;
}

List<ArtistGroup> groupByArtist(List<TrackItem> tracks) {
  final map = <String, List<TrackItem>>{};
  for (final track in tracks) {
    map.putIfAbsent(track.artistLabel, () => <TrackItem>[]).add(track);
  }
  final groups = <ArtistGroup>[
    for (final entry in map.entries)
      ArtistGroup(
        name: entry.key,
        tracks: entry.value
          ..sort((a, b) {
            final byAlbum = _compareText(a.album, b.album);
            return byAlbum != 0 ? byAlbum : _compareInAlbum(a, b);
          }),
        albums: entry.value.map((track) => track.albumLabel).toSet().length,
      ),
  ]..sort((a, b) => _compareText(a.name, b.name));
  return groups;
}

String _commonArtist(List<TrackItem> list) {
  final first = list.first.artistLabel;
  return list.every((track) => track.artistLabel == first)
      ? first
      : 'Various artists';
}
