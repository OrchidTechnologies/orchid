import 'dart:io';
import 'package:flutter/foundation.dart';
import 'orchid_log.dart';

/// Support overriding the platform for testing.
class OrchidPlatform {
  // To maintain synchronous operation this value is set on startup and
  // after changing the advanced config (which may override it).
  static bool pretendToBeAndroid = false;

  static bool get isMacOS {
    try {
      return Platform.isMacOS;
    } catch (e) {
      // e.g. Unsupported operation: Platform._operatingSystem on web.
      print(e);
      return false;
    }
  }

  // TODO: The MobilScanner package does support web but we do not have it set up.
  static bool doesNotSupportScanning =
      OrchidPlatform.isWeb ||
      OrchidPlatform.isWindows ||
      OrchidPlatform.isLinux;

  static bool supportsScanning = !doesNotSupportScanning;

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

  static bool get isWeb {
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
      return 'unknown';
    }
  }
}
