import 'package:flutter/foundation.dart';

abstract class UserConfig {
  @protected
  String? get(String expression);

  bool evalBoolDefault(String expression, bool defaultValue) {
    try {
      return evalBool(expression);
    } catch (err) {
      return defaultValue;
    }
  }

  bool evalBool(String expression) {
    var val = get(expression);
    if (val?.toLowerCase() == 'true') {
      return true;
    }
    if (val?.toLowerCase() == 'false') {
      return false;
    }
    throw Exception("Expression not a boolean: $val");
  }

  int evalIntDefault(String expression, int defaultValue) {
    try {
      return evalInt(expression);
    } catch (err) {
      //log("evalIntDefault: $err");
      return defaultValue;
    }
  }

  int? evalIntDefaultNull(String expression) {
    try {
      return evalInt(expression);
    } catch (err) {
      //log("evalIntDefault: $err");
      return null;
    }
  }

  int evalInt(String expression) {
    var val = get(expression);
    try {
      return int.parse(val.toString());
    } catch (err) {
      throw Exception(
          "Expression not int: $val, type=${val.runtimeType}, $err");
    }
  }

  double evalDoubleDefault(String expression, double defaultValue) {
    try {
      return evalDouble(expression);
    } catch (err) {
      return defaultValue;
    }
  }

  double? evalDoubleDefaultNull(String expression) {
    try {
      return evalDouble(expression);
    } catch (err) {
      return null;
    }
  }

  double evalDouble(String expression) {
    var val = get(expression);
    try {
      return double.parse(val!);
    } catch (err) {
      throw Exception("Expression not double: $val, $err");
    }
  }

  String evalStringDefault(String expression, String defaultValue) {
    try {
      return evalString(expression) ?? defaultValue;
    } catch (err) {
      return defaultValue;
    }
  }

  String? evalStringDefaultNullable(String expression, String? defaultValue) {
    try {
      return evalString(expression);
    } catch (err) {
      return defaultValue;
    }
  }

  String? evalStringDefaultNull(String expression) {
    try {
      return evalString(expression);
    } catch (err) {
      return null;
    }
  }

  String? evalString(String expression) {
    return get(expression);
  }
}

class MapUserConfig extends UserConfig {
  final Map<String, String> map;

  MapUserConfig(this.map);

  @override
  String? get(String expression) {
    return map[expression];
  }
}
