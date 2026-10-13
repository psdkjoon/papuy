enum MusicSort {
  title('Title'),
  artist('Artist'),
  added('Recently added'),
  duration('Duration');

  const MusicSort(this.label);

  final String label;
}
