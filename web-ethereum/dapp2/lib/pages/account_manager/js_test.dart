@JS()
library javascript_bundler;

import 'package:js/js.dart';

// Calls invoke JavaScript `JSON.stringify(obj)`.
//@JS('JSON.stringify')
//external String stringify(Object obj);

@JS('confirm')
external void showConfirm(String text);

