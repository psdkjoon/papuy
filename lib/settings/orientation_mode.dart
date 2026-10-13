enum OrientationMode {
  auto('Automatic'),
  landscape('Landscape'),
  portrait('Portrait'),
  sensor('Follow sensor');

  const OrientationMode(this.label);

  final String label;

  OrientationMode get next => values[(index + 1) % values.length];
}
