enum AspectMode {
  fit('Fit', null),
  fill('Fill', null),
  stretch('Stretch', null),
  wide('16:9', 16 / 9),
  standard('4:3', 4 / 3),
  cinema('21:9', 21 / 9);

  const AspectMode(this.label, this.ratio);

  final String label;
  final double? ratio;

  AspectMode get next => values[(index + 1) % values.length];
}
