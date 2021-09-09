import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'orchid_log_api.dart';

/// Support overriding the platform for testing.
class OrchidPlatform {
  // To maintain synchronous operation this value is set on startup and
  // after changing the advanced config (which may override it).
  static bool pretendToBeAndroid = false;

  /// If non-null this is a language code with optional country code, e.g.
  /// en or en_US
  static String languageOverride;

  /// Get the language code fro the language override
  static String get languageOverrideCode {
    return languageOverride.split('_')[0];
  }

  /// Get the country code fro the language override or null if there is none.
  static String get languageOverrideCountry {
    return languageOverride.contains('_')
        ? languageOverride.split('_')[1]
        : null;
  }

  /// lang should be a language code with optional country code, e.g.
  /// en or en_US
  static bool hasLanguage(String lang) {
    return S.supportedLocales
        .map((e) => (e.countryCode != null && e.countryCode.isNotEmpty)
            ? e.languageCode + '_' + e.countryCode
            : e.languageCode)
        .contains(lang);
  }

  // Providing this static snapshot of the locale for use in the
  // api layer that does not have access to the context.
  // This should be updated on locale changes from the context.
  static Locale staticLocale;

  static bool get isMacOS {
    try {
      return Platform.isMacOS;
    } catch (e) {
      // e.g. Unsupported operation: Platform._operatingSystem on web.
      print(e);
      return false;
    }
  }

  static bool get isLinux {
    try {
      return Platform.isLinux;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static bool get isWindows {
    try {
      return Platform.isWindows;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static bool get isAndroid {
    try {
      return pretendToBeAndroid || Platform.isAndroid;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static bool get isIOS {
    try {
      return !pretendToBeAndroid && Platform.isIOS;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static bool get isWeb{
    return kIsWeb;
  }

  static bool get isApple {
    return isIOS || isMacOS;
  }

  static bool get isNotApple {
    return !isApple;
  }

  static bool get isDesktop {
    return isMacOS || isLinux || isWindows;
  }

  static bool get hasPurchase {
    return isApple || isAndroid;
  }

  static String get operatingSystem {
    try {
      if (kIsWeb) {
        return 'web';
      }
      return Platform.operatingSystem;
    } catch (err) {
      log("exception fetching osname: $err");
      return "unknown";
    }
  }

}
