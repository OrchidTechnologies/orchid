import 'package:dartjsengine/dartjsengine.dart';
import 'package:jsparser/jsparser.dart';

class JSConfig {
  var jsEngine = JSEngine();

  JSConfig(String js) {
    // parsejs doesn't like an empty input or statement
    if (js == null || js.trim().isEmpty) {
      js = "{}";
    }
    Program jsProgram = parsejs(js, filename: 'program.js');
    jsEngine.visitProgram(jsProgram);
  }

  bool evalBoolDefault(String expression, bool defaultValue) {
    try {
      return evalBool(expression);
    } catch (err) {
      return defaultValue;
    }
  }

  bool evalBool(String expression) {
    JsObject val = _eval(expression);
    if (val?.valueOf is bool) {
      return val.valueOf;
    }
    throw Exception("Expression not a boolean: $val");
  }

  int evalIntDefault(String expression, int defaultValue) {
    try {
      return evalInt(expression);
    } catch (err) {
      return defaultValue;
    }
  }

  int evalInt(String expression) {
    JsObject val = _eval(expression);
    if (val?.valueOf is int) {
      return val.valueOf;
    }
    throw Exception("Expression not int: $val");
  }

  String evalStringDefault(String expression, String defaultValue) {
    try {
      return evalString(expression);
    } catch (err) {
      return defaultValue;
    }
  }

  String evalString(String expression) {
    JsObject val = _eval(expression);
    if (val?.valueOf is String) {
      return val.valueOf;
    }
    throw Exception("Expression not a string: $val");
  }

  JsObject _eval(String expression) {
    JsObject val = jsEngine.visitProgram(parsejs(expression, filename: "eval"));
    return val;
  }
}
