enum LoopMode {
  off('Off', 'Repeat off'),
  all('All', 'Repeat all'),
  one('One', 'Repeat one');

  const LoopMode(this.label, this.toast);

  final String label;
  final String toast;

  LoopMode get next => values[(index + 1) % values.length];
}
