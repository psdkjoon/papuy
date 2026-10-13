abstract class AppMotion {
  static bool enabled = true;

  static Duration d(int milliseconds) =>
      enabled ? Duration(milliseconds: milliseconds) : Duration.zero;
}
