import 'dart:io';

import 'dart:ui';

/// Support overriding the platform for testing.
class OrchidPlatform {
  // To maintain synchronous operation this value is set on startup and
  // after changing the advanced config (which may override it).
  static bool pretendToBeAndroid = false;

  // If non-null this is a language code.
  static String languageOverride;

  // Providing this static snapshot of the locale for use in the
  // api layer that does not have access to the context.
  // This should be updated on locale changes from the context.
  static Locale staticLocale;

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
