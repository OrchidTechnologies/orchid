import 'dart:async' show Future;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class OrchidDocs {
  static Future<String> openSourceLicenses() async {
    return await rootBundle.loadString('assets/docs/open_source.txt');
  }
  static Future<String> privacyPolicy() async {
    return await rootBundle.loadString('assets/docs/privacy.txt');
  }
  static Future<String> helpOverview(BuildContext context) async {
    Locale locale = Localizations.localeOf(context);
    print("xxx: locale = $locale");
    var languageCode = locale.languageCode.toLowerCase();
    if (languageCode.endsWith('_')) {
      languageCode = languageCode.substring(0, languageCode.length-1);
    }
    try {
      return await _helpOverview(languageCode);
    } catch(err) {
      return await _helpOverview('en');
    }
  }
  static Future<String> _helpOverview(String localeSuffix) async {
    var path = 'assets/docs/help/help_';
    return await rootBundle.loadString(path + localeSuffix + '.html');
  }
}
