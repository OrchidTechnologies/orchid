import 'dart:io';

/// Support overriding the platform for testing.
class OrchidPlatform {
  // To maintain synchronous operation this value is set on startup and
  // after changing the advanced config (which may override it).
  static bool pretendToBeAndroid = false;

  // If non-null this is a language code.
  static String languageOverride;

  static bool get isMacOS {
    return !pretendToBeAndroid && Platform.isMacOS;
  }

  static bool get isWindows {
    return !pretendToBeAndroid && Platform.isWindows;
  }

  static bool get isAndroid {
    return pretendToBeAndroid || Platform.isAndroid;
  }

  static bool get isIOS {
    return !pretendToBeAndroid && Platform.isIOS;
  }

  static bool get isApple {
    return isIOS || isMacOS;
  }

  static bool get isNotApple {
    return !isApple;
  }
}
