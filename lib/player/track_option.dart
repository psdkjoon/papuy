class TrackOption {
  const TrackOption({
    required this.type,
    required this.group,
    required this.index,
    required this.label,
    required this.selected,
  });

  factory TrackOption.fromMap(Map<Object?, Object?> map) {
    return TrackOption(
      type: (map['type'] as String?) ?? 'audio',
      group: (map['group'] as num?)?.toInt() ?? 0,
      index: (map['index'] as num?)?.toInt() ?? 0,
      label: (map['label'] as String?) ?? 'Track',
      selected: map['selected'] == true,
    );
  }

  static List<TrackOption> parseList(Object? raw) {
    if (raw is! List<Object?>) return const <TrackOption>[];
    return <TrackOption>[
      for (final item in raw)
        if (item is Map<Object?, Object?>) TrackOption.fromMap(item),
    ];
  }

  final String type;
  final int group;
  final int index;
  final String label;
  final bool selected;
}
