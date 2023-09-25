// import 'package:orchid/util/strings.dart';
extension StringExtensions on String {
  String prefix(int len, {String elide = "…"}) {
    return this.substring(0, len) + elide;
  }

  String suffix(int len) {
    if (this.length <= len) {
      return this;
    } else {
      return substring(this.length - len);
    }
  }

  bool get looksLikeUrl {
    return this.toLowerCase().startsWith('https://');
  }

  bool get isValidURL {
    var urlPattern =
        r"(https?|http)://([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?";
    var match = RegExp(urlPattern, caseSensitive: false).firstMatch(this);
    return match != null;
  }
}
