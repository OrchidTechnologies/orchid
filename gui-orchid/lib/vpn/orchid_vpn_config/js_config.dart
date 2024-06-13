import 'dart:convert';
import 'package:orchid/util/user_config.dart';
import 'package:flutter_js/flutter_js.dart';

class JSConfig extends UserConfig {
  final jsEngine = getJavascriptRuntime(forceJavascriptCoreOnAndroid: false);

  JSConfig(String? js) {
    // parsejs doesn't like an empty input or statement
    if (js == null || js.trim().isEmpty) {
      js = "{}";
    }
    jsEngine.evaluate(js);
  }

  dynamic evalObject(String expression) {
    return jsonDecode(
        jsEngine.evaluate("JSON.stringify($expression)").toString());
  }

  @override
  String? get(String expression) {
    var result = jsEngine.evaluate(expression).toString();
    // Map undefined variable references to null
    if (result == 'undefined' ||
        //
        // This api returns string error messages from the underlying JS engines.
        //
        // On Apple platforms we get the following:
        result.startsWith("ERROR: Can't find variable:") ||
        //
        // On Android we get the following:
        result.startsWith("ReferenceError:")
        //
        // Note: we could force the use of the JavaScriptCore engine on Android
        // by setting a parameter on getJavaScriptRuntime() but we would need to add the
        // Android dependency implementation to the build:
        // "com.github.fast-development.android-js-runtimes:fastdev-jsruntimes-jsc:0.3.4"
        // See the readme for: https://github.com/abner/flutter_js
    ) {
      return null;
    }
    return result;
  }
}
