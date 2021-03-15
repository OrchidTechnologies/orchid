
extension StringExtensions on String {
  String prefix(int len, {String elide = "…"}) {
    return this.substring(0, len) + elide;
  }
}

