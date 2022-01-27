
// import 'package:orchid/util/localization.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension LocalizationStateExtensions on State {
  S get s {
    return S.of(context);
  }
}

extension LocalizationContextExtensions on BuildContext {
  S get s {
    return S.of(this);
  }
}
