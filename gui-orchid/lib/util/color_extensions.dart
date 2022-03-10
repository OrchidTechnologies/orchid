import 'dart:ui';

// https://stackoverflow.com/a/50081214/74975
extension ColorExtensions on Color {
  /// From a JS style color string
  static Color fromHexString(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// To a JS style color string
  String toHexString({
    bool leadingHashSign = true,
    bool includeAlpha = true,
  }) =>
      '${leadingHashSign ? '#' : ''}' +
      (includeAlpha ? '${alpha.toRadixString(16).padLeft(2, '0')}' : '') +
      '${red.toRadixString(16).padLeft(2, '0')}' +
      '${green.toRadixString(16).padLeft(2, '0')}' +
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
