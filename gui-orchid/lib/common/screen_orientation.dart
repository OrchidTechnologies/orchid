import 'package:flutter/services.dart';

class ScreenOrientation {

  /// Reset to the app default
  static Future<void> reset() {
    return portrait();
  }

  /// Allow all screen orientations
  static Future<void> all() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
  }

  /// Allow only portrait orientations
  static Future<void> portrait() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
