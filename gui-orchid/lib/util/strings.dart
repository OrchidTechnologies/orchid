
extension StringExtensions on String {
  String prefix(int len, {String elide = "…"}) {
    return this.substring(0, len) + elide;
  }

  String trimTo(int maxLen) {
    return this.length > maxLen ? this.substring(0, maxLen) : this;
  }

}

/// Work around log line length limits
void printWrapped(String text) {
  final pattern = new RegExp('.{1,800}');
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

/// Recursively descend the json and trim long strings
Map<String, dynamic> trimLongStrings(Map<String, dynamic> json,
    {int max: 32}) {
  return json.map((String key, dynamic value) {
    if (value is String && value.length > max) {
      value = value.toString().substring(0, max) + '...';
    }
    if (value is Map<String, dynamic>) {
      return MapEntry(key, trimLongStrings(value));
    }
    return MapEntry(key, value);
  });
}

