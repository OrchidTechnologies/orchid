import 'dart:async' show Future;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'orchid_platform.dart';

class OrchidDocs {
  static Future<String> openSourceLicenses() async {
    return await rootBundle.loadString('assets/docs/open_source.txt');
  }

  static Future<String> privacyPolicy() async {
    return await rootBundle.loadString('assets/docs/privacy.txt');
  }

  /// Fetch the licenses for Flutter packages used by the front end.
  static Future<String> flutterLicenseRegistryText() async {
    final div = '-' * 40 + '\n';
    return (await LicenseRegistry.licenses.toList()).map((license) {
      final text = StringBuffer();
      text.write(div);
      final packages = license.packages.toList();
      text.write(
          packages.length > 1 ? 'Flutter Packages: ' : 'Flutter Package: ');
      text.writeAll(license.packages, ', ');
      text.write('\n');
      text.write(div);
      text.writeAll(license.paragraphs.map((e) => e.text), '\n');
      return text.toString();
    }).join('\n\n');
  }

  static Future<String> helpOverview(BuildContext context) async {
    Locale locale = Localizations.localeOf(context);
    var languageCode = locale.languageCode.toLowerCase();
    if (languageCode.endsWith('_')) {
      languageCode = languageCode.substring(0, languageCode.length - 1);
    }
    try {
      return await _helpOverview(languageCode);
    } catch (err) {
      return await _helpOverview('en');
    }
  }

  static Future<String> _helpOverview(String localeSuffix) async {
    var path = 'assets/docs/help/help_';
    var html = await rootBundle.loadString(path + localeSuffix + '.html');
    return renderHtmlForPlatform(html);
  }

  /// Exclude sections containing platform-paramaterized HTML comments
  /// of the form:
  ///
  ///   <!-- BEGIN: EXCLUDE(iOS, MacOS) -->
  ///   <p>Excluded content!</p>
  ///   <!-- END: EXCLUDE -->
  ///
  static String renderHtmlForPlatform(String html) {
    RegExp exp = new RegExp(
      r'<!-- *BEGIN: *EXCLUDE\((.*?)\) *-->.*?<!-- *END: *EXCLUDE.*?-->',
      dotAll: true,
    );
    return html.replaceAllMapped(exp, (match) {
      String platform = OrchidPlatform.operatingSystem.toLowerCase();
      String? targetPlatforms = match.group(1)?.toLowerCase();
      if (targetPlatforms != null &&
          targetPlatforms.split(RegExp(r' *, *')).contains(platform)) {
        return ''; // exclude, replace with nothing.
      }
      return match.group(0) ?? ''; // include
    });
  }
}
