
extension StringExtensions on String {
  String prefix(int len, {String elide = "…"}) {
    return this.substring(0, len) + elide;
  }

  String suffix(int len) {
    if (this.length <= len) { return this; }
    else {
      return substring(this.length - len);
    }
  }

}

/// Work around log line length limits
void printWrapped(String text) {
  final pattern = new RegExp('.{1,800}');
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

