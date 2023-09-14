import 'package:orchid/api/preferences/observable_preference.dart';
import 'user_preferences.dart';
import 'package:orchid/api/orchid_eth/orchid_chain_config.dart';
import 'package:orchid/api/preferences/user_configured_chain_preferences.dart';
import 'chain_config_preferences.dart';

class UserPreferencesUI {
  static final UserPreferencesUI _singleton = UserPreferencesUI._internal();

  factory UserPreferencesUI() {
    return _singleton;
  }

  UserPreferencesUI._internal();

  ///
  /// UI
  ///

  /// User configuration JS for app customization and testing.
  ObservableStringPreference userConfig =
      ObservableStringPreference(_UserPreferenceKeyUI.UserConfig);

  /// User locale override (e.g. en, pt_BR)
  ObservableStringPreference languageOverride =
      ObservableStringPreference(_UserPreferenceKeyUI.LanguageOverride);

  /// Identicons UI
  ObservableBoolPreference useBlockiesIdenticons = ObservableBoolPreference(
      _UserPreferenceKeyUI.UseBlockiesIdenticons,
      defaultValue: true);

  ///
  /// Chain Config
  ///

  /// User Chain config overrides
  // Note: Now that we have fully user-configurable chains we should probably
  // Note: fold this into that structure.
  ObservableChainConfigPreference chainConfig =
  ObservableChainConfigPreference(_UserPreferenceKeyUI.ChainConfig);

  /// User Chain config overrides
  // Note: Now that we have fully user-configurable chains we should probably
  // Note: fold this into that structure.
  ChainConfig? chainConfigFor(int chainId) {
    return ChainConfig.map(chainConfig.get()!)[chainId];
  }

  /// Fully user configured chains.
  ObservableUserConfiguredChainPreference userConfiguredChains =
  ObservableUserConfiguredChainPreference(
      _UserPreferenceKeyUI.UserConfiguredChains);
}

enum _UserPreferenceKeyUI implements UserPreferenceKey {
  UserConfig,
  LanguageOverride,
  UseBlockiesIdenticons,
  ChainConfig,
  UserConfiguredChains,
}
