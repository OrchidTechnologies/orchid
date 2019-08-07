import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;

class OrchidDocs {
  static Future<String> openSourceLicenses() async {
    return await rootBundle.loadString('assets/docs/open_source.txt');
  }
  static Future<String> privacyPolicy() async {
    return await rootBundle.loadString('assets/docs/privacy.txt');
  }
}
