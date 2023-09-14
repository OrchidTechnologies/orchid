import 'dart:ui';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/util/hex.dart';

/// This supports user supplied parameters via the URL parameters in the web
/// context or conceivably via the CLI in the future.
/// See UserPreferences() for cross-platform application user data storage.
/// See also OrchidUserConfig which supports stored JS configuration from user preferences.
class OrchidUserParams {
  static final OrchidUserParams _shared = OrchidUserParams._internal();

  OrchidUserParams._internal();

  factory OrchidUserParams() {
    return _shared;
  }

  Map<String, String> get params {
    // The 'base' URL is the page on Web or a URI for the current working directory on mobile.
    return Uri.base.queryParameters;
  }

  /// Return any query params as a JS string.
  /// e.g. '?foo=42&bar=43' => 'foo=42;bar=43;'
  String asJS() {
    return params.entries.map((e) => "${e.key}=${e.value};").join();
  }

  String? get(String name) {
    return params[name];
  }

  Color? getColor(String name) {
    var svalue = params[name];
    if (svalue == null) {
      return null;
    }
    try {
      return Color(int.parse(Hex.remove0x(svalue), radix: 16));
    } catch (err) {
      log("Error in color: $err");
      return null;
    }
  }

  bool has(String name) {
    return get(name) != null;
  }

  /// testing flag
  bool get test {
    return get('test') != null;
  }

  /// Support testing of unknown chain functionality by forcing unrecognized chain.
  bool get newchain {
    return get('newchain') != null;
  }
}
