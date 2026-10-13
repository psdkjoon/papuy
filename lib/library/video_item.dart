class VideoItem {
  const VideoItem({
    required this.id,
    required this.name,
    required this.folder,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.added,
    required this.uri,
  });

  factory VideoItem.fromMap(Map<Object?, Object?> map) {
    return VideoItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: (map['name'] as String?) ?? '',
      folder: (map['folder'] as String?) ?? 'Unknown',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      sizeBytes: (map['size'] as num?)?.toInt() ?? 0,
      added: (map['added'] as num?)?.toInt() ?? 0,
      uri: (map['uri'] as String?) ?? '',
    );
  }

  factory VideoItem.external(String uri, String name) {
    return VideoItem(
      id: -(uri.hashCode & 0x3fffffff) - 1,
      name: name,
      folder: 'Opened',
      durationMs: 0,
      width: 0,
      height: 0,
      sizeBytes: 0,
      added: 0,
      uri: uri,
    );
  }

  final int id;
  final String name;
  final String folder;
  final int durationMs;
  final int width;
  final int height;
  final int sizeBytes;
  final int added;
  final String uri;

  bool get isExternal => id < 0;

  Duration get duration => Duration(milliseconds: durationMs);

  String get nameWithoutExtension {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot > 0 && name.length - dot <= 6
        ? name.substring(dot + 1).toUpperCase()
        : '';
  }

  String get info {
    if (sizeBytes <= 0) return extension;
    final megabytes = sizeBytes / 1048576;
    final size = megabytes >= 1024
        ? '${(megabytes / 1024).toStringAsFixed(1)} GB'
        : '${megabytes.round()} MB';
    return height > 0 ? '${height}p · $size' : size;
  }
}
