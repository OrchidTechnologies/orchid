import 'dart:ui';
import 'package:flutter/src/widgets/localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';

/// Supports app localization and language override
class OrchidLanguage {
  /// Language code to display name.
  static final Map<String, String> languages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'hi': 'हिंदी',
    'id': 'Bahasa Indonesia',
    'it': 'Italiano',
    'ja': '日本語',
    'ko': '한국어',
    'pt': 'Português',
    'pt_BR': 'Português do Brasil',
    'ru': 'Pусский',
    'tr': 'Türkçe',
    'zh': '中文',
  };

  // Providing this static snapshot of the locale for use in the
  // api layer that does not have access to the context.
  // This (late init non-nullable) should be updated on locale changes from the context.
  static late Locale staticLocale;

  static bool get hasLanguageOverride {
    return languageOverride != null;
  }

  /// Fetch any language override from the environment or user config.
  /// If non-null this is a language code with optional country code, e.g.
  /// en or en_US
  static String? get languageOverride {
    String? envLanguageOverride =
        const String.fromEnvironment('language', defaultValue: '');
    if (envLanguageOverride == '')
      envLanguageOverride =
          OrchidUserConfig().getUserConfig().evalStringDefaultNull('lang');

    if (envLanguageOverride != null && hasLanguage(envLanguageOverride)) {
      return envLanguageOverride;
    }
    return UserPreferences.initialized
        ? UserPreferencesUI().languageOverride.get()
        : null;
  }

  /// Get the language code from the language override
  static String? get languageOverrideCode {
    return languageOverride == null ? null : languageOverride!.split('_')[0];
  }

  /// Get the country code from the language override or null if there is none.
  static String? get languageOverrideCountry {
    if (languageOverride == null) {
      return null;
    }
    return languageOverride!.contains('_')
        ? languageOverride!.split('_')[1]
        : null;
  }

  /// Return an overridden locale or null if there is no override.
  static Locale? get languageOverrideLocale {
    if (OrchidLanguage.languageOverride == null) {
      return null;
    }
    return Locale.fromSubtags(
        languageCode: languageOverrideCode!,
        countryCode: languageOverrideCountry);
  }

  /// lang should be a language code with optional country code, e.g.
  /// en or en_US
  static bool hasLanguage(String lang) {
    return S.supportedLocales
        .map((e) => (e.countryCode != null && e.countryCode!.isNotEmpty)
            ? e.languageCode + '_' + e.countryCode!
            : e.languageCode)
        .contains(lang);
  }

  static final List<LocalizationsDelegate<Object>> localizationsDelegates = [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
      ] +
      GlobalMaterialLocalizations.delegates
          .cast<LocalizationsDelegate<Object>>();

  // Note: It is no longer strictly necessary to limit the locales for override.
  static Iterable<Locale> get supportedLocales {
    return OrchidLanguage.languageOverride == null
        ? S.supportedLocales
        : languageOverrideLocale != null
            ? [languageOverrideLocale!]
            : [];
  }
}
