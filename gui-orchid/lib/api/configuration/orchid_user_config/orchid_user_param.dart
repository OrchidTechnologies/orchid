
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
    return Uri.base.queryParameters;
  }

  /// Return any query params as a JS string.
  /// e.g. '?foo=42&bar=43' => 'foo=42;bar=43;'
  String asJS() {
    return params.entries.map((e) => "${e.key}=${e.value};").join();
  }

  String get(String name) {
    return params[name];
  }

  bool has(String name) {
    return get(name) != null;
  }

  bool get test {
    return get('test') != null;
  }
}
