class SubtitleCue {
  const SubtitleCue(this.start, this.end, this.text);

  final Duration start;
  final Duration end;
  final String text;
}

List<SubtitleCue> parseSrt(String input) {
  final text = input
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceFirst('\u{FEFF}', '');
  final cues = <SubtitleCue>[];
  for (final block in text.split(RegExp(r'\n\s*\n'))) {
    final lines = block.trim().split('\n');
    final arrow = lines.indexWhere((line) => line.contains('-->'));
    if (arrow < 0) continue;
    final parts = lines[arrow].split('-->');
    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);
    if (start == null || end == null) continue;
    final body = lines
        .sublist(arrow + 1)
        .join('\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\{[^}]*\}'), '')
        .trim();
    if (body.isEmpty) continue;
    cues.add(SubtitleCue(start, end, body));
  }
  return cues;
}

Duration? _parseTime(String raw) {
  final match = RegExp(r'(\d+):(\d+):(\d+)[,.](\d+)').firstMatch(raw.trim());
  if (match == null) return null;
  final millis = int.parse(match.group(4)!.padRight(3, '0').substring(0, 3));
  return Duration(
    hours: int.parse(match.group(1)!),
    minutes: int.parse(match.group(2)!),
    seconds: int.parse(match.group(3)!),
    milliseconds: millis,
  );
}
