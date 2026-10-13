enum SortKey {
  date('Date added'),
  name('Name'),
  duration('Duration'),
  size('Size'),
  played('Last played');

  const SortKey(this.label);

  final String label;
}
