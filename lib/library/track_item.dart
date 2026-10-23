class TrackItem {
  const TrackItem({
    required this.id,
    required this.name,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.durationMs,
    required this.sizeBytes,
    required this.added,
    required this.number,
    required this.uri,
    this.path = '',
  });

  factory TrackItem.fromMap(Map<Object?, Object?> map) {
    final name = (map['name'] as String?) ?? '';
    final title = (map['title'] as String?) ?? '';
    return TrackItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: name,
      title: title.isNotEmpty ? title : _withoutExtension(name),
      artist: (map['artist'] as String?) ?? '',
      album: (map['album'] as String?) ?? '',
      albumId: (map['albumId'] as num?)?.toInt() ?? 0,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      sizeBytes: (map['size'] as num?)?.toInt() ?? 0,
      added: (map['added'] as num?)?.toInt() ?? 0,
      number: (map['track'] as num?)?.toInt() ?? 0,
      uri: (map['uri'] as String?) ?? '',
      path: (map['path'] as String?) ?? '',
    );
  }

  factory TrackItem.external(String uri, String name) {
    return TrackItem(
      id: -(uri.hashCode & 0x3fffffff) - 1,
      name: name,
      title: _withoutExtension(name),
      artist: '',
      album: '',
      albumId: 0,
      durationMs: 0,
      sizeBytes: 0,
      added: 0,
      number: 0,
      uri: uri,
    );
  }

  static String _withoutExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static const Set<String> extensions = <String>{
    'mp3',
    'm4a',
    'aac',
    'flac',
    'wav',
    'ogg',
    'oga',
    'opus',
    'wma',
    'amr',
    'mka',
  };

  static bool isAudioFile(String name, String mime) {
    if (mime.toLowerCase().startsWith('audio/')) return true;
    if (mime.toLowerCase().startsWith('video/')) return false;
    return looksLikeAudio(name);
  }

  static bool looksLikeAudio(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return extensions.contains(name.substring(dot + 1).toLowerCase());
  }

  final int id;
  final String name;
  final String title;
  final String artist;
  final String album;
  final int albumId;
  final int durationMs;
  final int sizeBytes;
  final int added;
  final int number;
  final String uri;
  final String path;

  bool get isExternal => id < 0;

  @override
  bool operator ==(Object other) => other is TrackItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Duration get duration => Duration(milliseconds: durationMs);

  String get artistLabel => artist.isEmpty ? 'Unknown artist' : artist;

  String get albumLabel => album.isEmpty ? 'Unknown album' : album;

  String get subtitle {
    if (artist.isEmpty && album.isEmpty) return '';
    if (artist.isEmpty) return album;
    if (album.isEmpty) return artist;
    return '$artist · $album';
  }
}
