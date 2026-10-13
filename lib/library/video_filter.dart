enum VideoFilter {
  all('All'),
  favorites('Favorites'),
  continuing('Continue'),
  fresh('New');

  const VideoFilter(this.label);

  final String label;
}
