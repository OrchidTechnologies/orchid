import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension LocalizationStateExtensions on State {
  S get s {
    return S.of(context)!;
  }
}

extension LocalizationContextExtensions on BuildContext {
  Locale get locale {
    return Localizations.localeOf(this);
  }

  S get s {
    return S.of(this)!;
  }
}
