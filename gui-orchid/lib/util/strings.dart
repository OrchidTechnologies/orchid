
// import 'package:orchid/util/strings.dart';
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
