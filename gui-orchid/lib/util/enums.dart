
class Enums {
  static void _assertEnum(enumValue) {
    final comps = enumValue.toString().split('.');
    if (!(comps.length > 1 && comps[0] == enumValue.runtimeType.toString())) {
      throw Exception("Not an enum type: $enumValue");
    }
  }

  /// Render the suffix only
  /// e.g. TransactionType.None => "None"
  static String toStringValue(enumValue) {
    _assertEnum(enumValue);
    return enumValue.toString().split('.')[1];
  }

  /// Pick an enum value based on the suffix only, ignoring case.
  /// e.g. "none" => TransactionType.None
  static T fromString<T>(List<T> enumValues, String value) {
    if (value == null) { return null; }
    if (enumValues == null) {
      throw Exception("Enums: invalid values or value: $enumValues, $value");
    }
    return enumValues.singleWhere(
        (enumValue) => toStringValue(enumValue).toLowerCase() == value.toLowerCase(),
        orElse: () => null);
  }
}
