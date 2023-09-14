class Json {
  /// Recursively descend the json and trim long strings
  static Map<String, dynamic> trimLongStrings(Map<String, dynamic> json,
      {int max = 32}) {
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

  /// Parse either a native or string encoded int.
  static int toInt(dynamic value) {
    return value is int ? value : int.parse(value.toString());
  }

  static int toIntSafe(dynamic value, {required int defaultValue}) {
    try {
      return toInt(value);
    } catch (err) {
      return defaultValue;
    }
  }

  /// If the string is empty or whitespace return null, else
  /// return the trimmed string.
  static String? trimStringOrNull(String? value) {
    return value == null || value.trim().isEmpty ? null : value.trim();
  }

  /// Parse either a native or string encoded float.
  static double toDouble(dynamic value) {
    return value is double ? value : double.parse(value.toString());
  }
}
