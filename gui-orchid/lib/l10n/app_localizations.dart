import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh')
  ];

  /// Orchid network hop
  ///
  /// In en, this message translates to:
  /// **'Orchid Hop'**
  String get orchidHop;

  /// No description provided for @orchidDisabled.
  ///
  /// In en, this message translates to:
  /// **'Orchid disabled'**
  String get orchidDisabled;

  /// No description provided for @trafficMonitoringOnly.
  ///
  /// In en, this message translates to:
  /// **'Traffic monitoring only'**
  String get trafficMonitoringOnly;

  /// No description provided for @orchidConnecting.
  ///
  /// In en, this message translates to:
  /// **'Orchid connecting'**
  String get orchidConnecting;

  /// No description provided for @orchidDisconnecting.
  ///
  /// In en, this message translates to:
  /// **'Orchid disconnecting'**
  String get orchidDisconnecting;

  /// No description provided for @numHopsConfigured.
  ///
  /// In en, this message translates to:
  /// **'{num, plural, =0{No hops configured} =1{One hop configured} =2{Two hops configured} other{{num} hops configured}}'**
  String numHopsConfigured(int num);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @orchid.
  ///
  /// In en, this message translates to:
  /// **'Orchid'**
  String get orchid;

  /// No description provided for @openVPN.
  ///
  /// In en, this message translates to:
  /// **'OpenVPN'**
  String get openVPN;

  /// Network hops
  ///
  /// In en, this message translates to:
  /// **'Hops'**
  String get hops;

  /// Network traffic
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get traffic;

  /// No description provided for @curation.
  ///
  /// In en, this message translates to:
  /// **'Curation'**
  String get curation;

  /// No description provided for @signerKey.
  ///
  /// In en, this message translates to:
  /// **'Signer Key'**
  String get signerKey;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @curator.
  ///
  /// In en, this message translates to:
  /// **'Curator'**
  String get curator;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @settingsButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsButtonTitle;

  /// No description provided for @confirmThisAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm this action'**
  String get confirmThisAction;

  /// No description provided for @cancelButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelButtonTitle;

  /// No description provided for @changesWillTakeEffectInstruction.
  ///
  /// In en, this message translates to:
  /// **'Changes will take effect when the VPN is restarted.'**
  String get changesWillTakeEffectInstruction;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @configurationSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get configurationSaved;

  /// No description provided for @whoops.
  ///
  /// In en, this message translates to:
  /// **'Whoops'**
  String get whoops;

  /// No description provided for @configurationFailedInstruction.
  ///
  /// In en, this message translates to:
  /// **'Configuration failed to save.  Please check syntax and try again.'**
  String get configurationFailedInstruction;

  /// No description provided for @addHop.
  ///
  /// In en, this message translates to:
  /// **'Add Hop'**
  String get addHop;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @invalidQRCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR Code'**
  String get invalidQRCode;

  /// No description provided for @theQRCodeYouScannedDoesNot.
  ///
  /// In en, this message translates to:
  /// **'The QR code you scanned does not contain a valid account configuration.'**
  String get theQRCodeYouScannedDoesNot;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid Code'**
  String get invalidCode;

  /// No description provided for @theCodeYouPastedDoesNot.
  ///
  /// In en, this message translates to:
  /// **'The code you pasted does not contain a valid account configuration.'**
  String get theCodeYouPastedDoesNot;

  /// No description provided for @openVPNHop.
  ///
  /// In en, this message translates to:
  /// **'OpenVPN Hop'**
  String get openVPNHop;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @config.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get config;

  /// No description provided for @pasteYourOVPN.
  ///
  /// In en, this message translates to:
  /// **'Paste your OVPN config file here'**
  String get pasteYourOVPN;

  /// No description provided for @enterYourCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials'**
  String get enterYourCredentials;

  /// No description provided for @enterLoginInformationInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter the login information for your VPN provider above. Then paste the contents of your provider’s OpenVPN config file into the field provided.'**
  String get enterLoginInformationInstruction;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @noVersion.
  ///
  /// In en, this message translates to:
  /// **'No version'**
  String get noVersion;

  /// No description provided for @orchidOverview.
  ///
  /// In en, this message translates to:
  /// **'Orchid Overview'**
  String get orchidOverview;

  /// No description provided for @defaultCurator.
  ///
  /// In en, this message translates to:
  /// **'Default Curator'**
  String get defaultCurator;

  /// No description provided for @queryBalances.
  ///
  /// In en, this message translates to:
  /// **'Query Balances'**
  String get queryBalances;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @manageConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Manage Configuration'**
  String get manageConfiguration;

  /// No description provided for @warningThesefeature.
  ///
  /// In en, this message translates to:
  /// **'Warning: These features are intended for advanced users only.  Please read all instructions.'**
  String get warningThesefeature;

  /// No description provided for @exportHopsConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Export Hops Configuration'**
  String get exportHopsConfiguration;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @warningExportedConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Warning: Exported configuration includes the signer private key secrets for the exported hops.  Revealing private keys exposes you to loss of all funds in the associated Orchid accounts.'**
  String get warningExportedConfiguration;

  /// No description provided for @importHopsConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Import Hops Configuration'**
  String get importHopsConfiguration;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @warningImportedConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Warning: Imported configuration will replace any existing hops that you have created in the app.  Signer keys previously generated or imported on this device will be retained and remain accessible for creating new hops, however all other configuration including OpenVPN hop configuration will be lost.'**
  String get warningImportedConfiguration;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @saveButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get saveButtonTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @newContent.
  ///
  /// In en, this message translates to:
  /// **'New Content'**
  String get newContent;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @connectionDetail.
  ///
  /// In en, this message translates to:
  /// **'Connection Detail'**
  String get connectionDetail;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @sourcePort.
  ///
  /// In en, this message translates to:
  /// **'Source Port'**
  String get sourcePort;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @destinationPort.
  ///
  /// In en, this message translates to:
  /// **'Destination Port'**
  String get destinationPort;

  /// No description provided for @generateNewKey.
  ///
  /// In en, this message translates to:
  /// **'Generate new key'**
  String get generateNewKey;

  /// No description provided for @importKey.
  ///
  /// In en, this message translates to:
  /// **'Import key'**
  String get importKey;

  /// No description provided for @nothingToDisplayYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to display yet. Traffic will appear here when there’s something to show.'**
  String get nothingToDisplayYet;

  /// No description provided for @disconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting...'**
  String get disconnecting;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @pushToConnect.
  ///
  /// In en, this message translates to:
  /// **'Push to connect.'**
  String get pushToConnect;

  /// No description provided for @orchidIsRunning.
  ///
  /// In en, this message translates to:
  /// **'Orchid is running!'**
  String get orchidIsRunning;

  /// No description provided for @pacPurchaseWaiting.
  ///
  /// In en, this message translates to:
  /// **'Purchase Waiting'**
  String get pacPurchaseWaiting;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @getHelpResolvingIssue.
  ///
  /// In en, this message translates to:
  /// **'Get help resolving this issue.'**
  String get getHelpResolvingIssue;

  /// No description provided for @copyDebugInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy Debug Info'**
  String get copyDebugInfo;

  /// No description provided for @contactOrchid.
  ///
  /// In en, this message translates to:
  /// **'Contact Orchid'**
  String get contactOrchid;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @clearThisInProgressTransactionExplain.
  ///
  /// In en, this message translates to:
  /// **'Clear this in-progress transaction. This will not refund your in-app purchase.  You must contact Orchid to resolve the issue.'**
  String get clearThisInProgressTransactionExplain;

  /// No description provided for @preparingPurchase.
  ///
  /// In en, this message translates to:
  /// **'Preparing Purchase'**
  String get preparingPurchase;

  /// No description provided for @retryingPurchasedPAC.
  ///
  /// In en, this message translates to:
  /// **'Retrying Purchase'**
  String get retryingPurchasedPAC;

  /// No description provided for @retryPurchasedPAC.
  ///
  /// In en, this message translates to:
  /// **'Retry Purchase'**
  String get retryPurchasedPAC;

  /// No description provided for @purchaseError.
  ///
  /// In en, this message translates to:
  /// **'Purchase Error'**
  String get purchaseError;

  /// No description provided for @thereWasAnErrorInPurchasingContact.
  ///
  /// In en, this message translates to:
  /// **'There was an error in purchasing.  Please contact Orchid Support.'**
  String get thereWasAnErrorInPurchasingContact;

  /// No description provided for @importAnOrchidAccount.
  ///
  /// In en, this message translates to:
  /// **'Import an Orchid Account'**
  String get importAnOrchidAccount;

  /// No description provided for @buyCredits.
  ///
  /// In en, this message translates to:
  /// **'Buy Credits'**
  String get buyCredits;

  /// No description provided for @linkAnOrchidAccount.
  ///
  /// In en, this message translates to:
  /// **'Link Orchid Account'**
  String get linkAnOrchidAccount;

  /// No description provided for @weAreSorryButThisPurchaseWouldExceedTheDaily.
  ///
  /// In en, this message translates to:
  /// **'We are sorry but this purchase would exceed the daily purchase limit for access credits.  Please try again later.'**
  String get weAreSorryButThisPurchaseWouldExceedTheDaily;

  /// No description provided for @marketStats.
  ///
  /// In en, this message translates to:
  /// **'Market Stats'**
  String get marketStats;

  /// No description provided for @balanceTooLow.
  ///
  /// In en, this message translates to:
  /// **'Balance too low'**
  String get balanceTooLow;

  /// No description provided for @depositSizeTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Deposit size too small'**
  String get depositSizeTooSmall;

  /// No description provided for @yourMaxTicketValueIsCurrentlyLimitedByYourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your max ticket value is currently limited by your balance of'**
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance;

  /// No description provided for @yourMaxTicketValueIsCurrentlyLimitedByYourDeposit.
  ///
  /// In en, this message translates to:
  /// **'Your max ticket value is currently limited by your deposit of'**
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit;

  /// No description provided for @considerAddingOxtToYourAccountBalance.
  ///
  /// In en, this message translates to:
  /// **'Consider adding OXT to your account balance.'**
  String get considerAddingOxtToYourAccountBalance;

  /// No description provided for @considerAddingOxtToYourDepositOrMovingFundsFrom.
  ///
  /// In en, this message translates to:
  /// **'Consider adding OXT to your deposit or moving funds from your balance to your deposit.'**
  String get considerAddingOxtToYourDepositOrMovingFundsFrom;

  /// No description provided for @prices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get prices;

  /// No description provided for @ticketValue.
  ///
  /// In en, this message translates to:
  /// **'Ticket Value'**
  String get ticketValue;

  /// No description provided for @costToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Cost to redeem:'**
  String get costToRedeem;

  /// No description provided for @viewTheDocsForHelpOnThisIssue.
  ///
  /// In en, this message translates to:
  /// **'View the docs for help on this issue.'**
  String get viewTheDocsForHelpOnThisIssue;

  /// No description provided for @goodForBrowsingAndLightActivity.
  ///
  /// In en, this message translates to:
  /// **'Good for browsing and light activity'**
  String get goodForBrowsingAndLightActivity;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more.'**
  String get learnMore;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @wireguardHop.
  ///
  /// In en, this message translates to:
  /// **'WireGuard®️ Hop'**
  String get wireguardHop;

  /// No description provided for @pasteYourWireguardConfigFileHere.
  ///
  /// In en, this message translates to:
  /// **'Paste your WireGuard®️ config file here'**
  String get pasteYourWireguardConfigFileHere;

  /// No description provided for @pasteTheCredentialInformationForYourWireguardProviderIntoThe.
  ///
  /// In en, this message translates to:
  /// **'Paste the credential information for your WireGuard®️ provider into the field above.'**
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe;

  /// No description provided for @wireguard.
  ///
  /// In en, this message translates to:
  /// **'WireGuard®️'**
  String get wireguard;

  /// No description provided for @clearAllLogData.
  ///
  /// In en, this message translates to:
  /// **'Clear all log data?'**
  String get clearAllLogData;

  /// No description provided for @thisDebugLogIsNonpersistentAndClearedWhenQuittingThe.
  ///
  /// In en, this message translates to:
  /// **'This debug log is non-persistent and cleared when quitting the app.'**
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe;

  /// No description provided for @itMayContainSecretOrPersonallyIdentifyingInformation.
  ///
  /// In en, this message translates to:
  /// **'It may contain secret or personally identifying information.'**
  String get itMayContainSecretOrPersonallyIdentifyingInformation;

  /// No description provided for @loggingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Logging enabled'**
  String get loggingEnabled;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @logging.
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get logging;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading ...'**
  String get loading;

  /// No description provided for @ethPrice.
  ///
  /// In en, this message translates to:
  /// **'ETH price:'**
  String get ethPrice;

  /// No description provided for @oxtPrice.
  ///
  /// In en, this message translates to:
  /// **'OXT price:'**
  String get oxtPrice;

  /// No description provided for @gasPrice.
  ///
  /// In en, this message translates to:
  /// **'Gas price:'**
  String get gasPrice;

  /// No description provided for @maxFaceValue.
  ///
  /// In en, this message translates to:
  /// **'Max face value:'**
  String get maxFaceValue;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @enterOpenvpnConfig.
  ///
  /// In en, this message translates to:
  /// **'Enter OpenVPN Config'**
  String get enterOpenvpnConfig;

  /// No description provided for @enterWireguardConfig.
  ///
  /// In en, this message translates to:
  /// **'Enter WireGuard®️ Config'**
  String get enterWireguardConfig;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get starting;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @whatsNewInOrchid.
  ///
  /// In en, this message translates to:
  /// **'What’s new in Orchid'**
  String get whatsNewInOrchid;

  /// No description provided for @orchidIsOnXdai.
  ///
  /// In en, this message translates to:
  /// **'Orchid is on xDai!'**
  String get orchidIsOnXdai;

  /// No description provided for @youCanNowPurchaseOrchidCreditsOnXdaiStartUsing.
  ///
  /// In en, this message translates to:
  /// **'You can now purchase Orchid credits on xDai! Start using the VPN for as little as \$1.'**
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing;

  /// No description provided for @xdaiAccountsForPastPurchases.
  ///
  /// In en, this message translates to:
  /// **'xDai accounts for past purchases'**
  String get xdaiAccountsForPastPurchases;

  /// No description provided for @forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave.
  ///
  /// In en, this message translates to:
  /// **'For any in-app purchase made before today, xDai funds have been added to the same account key. Have the bandwidth on us!'**
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave;

  /// No description provided for @newInterface.
  ///
  /// In en, this message translates to:
  /// **'New interface'**
  String get newInterface;

  /// No description provided for @accountsAreNowOrganizedUnderTheOrchidAddressTheyAre.
  ///
  /// In en, this message translates to:
  /// **'Accounts are now organized under the Orchid Address they are associated with.'**
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre;

  /// No description provided for @seeYourActiveAccountBalanceAndBandwidthCostOnThe.
  ///
  /// In en, this message translates to:
  /// **'See your active account balance and bandwidth cost on the home screen.'**
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe;

  /// No description provided for @seeOrchidcomForHelp.
  ///
  /// In en, this message translates to:
  /// **'See orchid.com for help.'**
  String get seeOrchidcomForHelp;

  /// No description provided for @payPerUseVpnService.
  ///
  /// In en, this message translates to:
  /// **'Pay Per Use VPN Service'**
  String get payPerUseVpnService;

  /// No description provided for @notASubscriptionCreditsDontExpire.
  ///
  /// In en, this message translates to:
  /// **'Not a subscription, credits don\'t expire'**
  String get notASubscriptionCreditsDontExpire;

  /// No description provided for @shareAccountWithUnlimitedDevices.
  ///
  /// In en, this message translates to:
  /// **'Share account with unlimited devices'**
  String get shareAccountWithUnlimitedDevices;

  /// No description provided for @theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn.
  ///
  /// In en, this message translates to:
  /// **'The Orchid Store is temporarily unavailable.  Please check back in a few minutes.'**
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn;

  /// No description provided for @talkingToPacServer.
  ///
  /// In en, this message translates to:
  /// **'Talking to Orchid Account Server'**
  String get talkingToPacServer;

  /// No description provided for @advancedConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Advanced Configuration'**
  String get advancedConfiguration;

  /// No description provided for @newWord.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newWord;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get efficiency;

  /// No description provided for @minTicketsAvailableTickets.
  ///
  /// In en, this message translates to:
  /// **'Min Tickets available: {tickets}'**
  String minTicketsAvailableTickets(int tickets);

  /// No description provided for @transactionSentToBlockchain.
  ///
  /// In en, this message translates to:
  /// **'Transaction Sent To Blockchain'**
  String get transactionSentToBlockchain;

  /// No description provided for @yourPurchaseIsCompleteAndIsNowBeingProcessedBy.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is complete and is now being processed by the xDai blockchain which can take up to a minute, sometimes longer. Pull down to refresh and your account with an updated balance will appear below.'**
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy;

  /// No description provided for @copyReceipt.
  ///
  /// In en, this message translates to:
  /// **'Copy Receipt'**
  String get copyReceipt;

  /// No description provided for @manageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage Accounts'**
  String get manageAccounts;

  /// No description provided for @configurationManagement.
  ///
  /// In en, this message translates to:
  /// **'Configuration Management'**
  String get configurationManagement;

  /// No description provided for @exportThisOrchidKey.
  ///
  /// In en, this message translates to:
  /// **'Export this Orchid Key'**
  String get exportThisOrchidKey;

  /// No description provided for @aQrCodeAndTextForAllTheOrchidAccounts.
  ///
  /// In en, this message translates to:
  /// **'A QR code and text for all the Orchid accounts associated with this key is below.'**
  String get aQrCodeAndTextForAllTheOrchidAccounts;

  /// No description provided for @importThisKeyOnAnotherDeviceToShareAllThe.
  ///
  /// In en, this message translates to:
  /// **'Import this key on another device to share all the Orchid accounts associated with this Orchid identity.'**
  String get importThisKeyOnAnotherDeviceToShareAllThe;

  /// No description provided for @orchidAccountInUse.
  ///
  /// In en, this message translates to:
  /// **'Orchid Account in use'**
  String get orchidAccountInUse;

  /// No description provided for @thisOrchidAccountIsInUseAndCannotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'This Orchid Account is in use and cannot be deleted.'**
  String get thisOrchidAccountIsInUseAndCannotBeDeleted;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh.'**
  String get pullToRefresh;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @pasteAnOrchidKeyFromTheClipboardToImportAll.
  ///
  /// In en, this message translates to:
  /// **'Paste an Orchid key from the clipboard to import all the Orchid accounts associated with that key.'**
  String get pasteAnOrchidKeyFromTheClipboardToImportAll;

  /// No description provided for @scanOrPasteAnOrchidKeyFromTheClipboardTo.
  ///
  /// In en, this message translates to:
  /// **'Scan or paste an Orchid key from the clipboard to import all the Orchid accounts associated with that key.'**
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @weRecommendBackingItUp.
  ///
  /// In en, this message translates to:
  /// **'We recommend <link>backing it up</link>.'**
  String get weRecommendBackingItUp;

  /// No description provided for @copiedOrchidIdentity.
  ///
  /// In en, this message translates to:
  /// **'Copied Orchid Identity'**
  String get copiedOrchidIdentity;

  /// No description provided for @thisIsNotAWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'This is not a wallet address.'**
  String get thisIsNotAWalletAddress;

  /// No description provided for @doNotSendTokensToThisAddress.
  ///
  /// In en, this message translates to:
  /// **'Do not send tokens to this address.'**
  String get doNotSendTokensToThisAddress;

  /// No description provided for @yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork.
  ///
  /// In en, this message translates to:
  /// **'Your Orchid Identity uniquely identifies you on the network.'**
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork;

  /// No description provided for @learnMoreAboutYourLinkorchidIdentitylink.
  ///
  /// In en, this message translates to:
  /// **'Learn more about your <link>Orchid Identity</link>.'**
  String get learnMoreAboutYourLinkorchidIdentitylink;

  /// No description provided for @analyzingYourConnections.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Your Connections'**
  String get analyzingYourConnections;

  /// No description provided for @analyzeYourConnections.
  ///
  /// In en, this message translates to:
  /// **'Analyze Your Connections'**
  String get analyzeYourConnections;

  /// No description provided for @networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets.
  ///
  /// In en, this message translates to:
  /// **'Network analysis uses your device\'s VPN facility to capture packets and analyze your traffic.'**
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets;

  /// No description provided for @networkAnalysisRequiresVpnPermissionsButDoesNotByItself.
  ///
  /// In en, this message translates to:
  /// **'Network analysis requires VPN permissions but does not by itself protect your data or hide your IP address.'**
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself;

  /// No description provided for @toGetTheBenefitsOfNetworkPrivacyYouMustConfigure.
  ///
  /// In en, this message translates to:
  /// **'To get the benefits of network privacy you must configure and activate a VPN connection from the home screen.'**
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure;

  /// No description provided for @turningOnThisFeatureWillIncreaseTheBatteryUsageOf.
  ///
  /// In en, this message translates to:
  /// **'Turning on this feature will increase the battery usage of the Orchid App.'**
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf;

  /// No description provided for @useAnOrchidAccount.
  ///
  /// In en, this message translates to:
  /// **'Use an Orchid Account'**
  String get useAnOrchidAccount;

  /// No description provided for @pasteAddress.
  ///
  /// In en, this message translates to:
  /// **'Paste Address'**
  String get pasteAddress;

  /// No description provided for @chooseAddress.
  ///
  /// In en, this message translates to:
  /// **'Choose Address'**
  String get chooseAddress;

  /// No description provided for @chooseAnOrchidAccountToUseWithThisHop.
  ///
  /// In en, this message translates to:
  /// **'Choose an Orchid Account to use with this hop.'**
  String get chooseAnOrchidAccountToUseWithThisHop;

  /// No description provided for @ifYouDontSeeYourAccountBelowYouCanUse.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t see your account below you can use the account manager to import, purchase, or create a new one.'**
  String get ifYouDontSeeYourAccountBelowYouCanUse;

  /// No description provided for @selectAnOrchidAccount.
  ///
  /// In en, this message translates to:
  /// **'Select an Orchid Account'**
  String get selectAnOrchidAccount;

  /// No description provided for @takeMeToTheAccountManager.
  ///
  /// In en, this message translates to:
  /// **'Take me to the Account Manager'**
  String get takeMeToTheAccountManager;

  /// No description provided for @funderAccount.
  ///
  /// In en, this message translates to:
  /// **'Funder Account'**
  String get funderAccount;

  /// No description provided for @orchidRunningAndAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Orchid running and analyzing'**
  String get orchidRunningAndAnalyzing;

  /// No description provided for @startingVpn.
  ///
  /// In en, this message translates to:
  /// **'(Starting VPN)'**
  String get startingVpn;

  /// No description provided for @disconnectingVpn.
  ///
  /// In en, this message translates to:
  /// **'(Disconnecting VPN)'**
  String get disconnectingVpn;

  /// No description provided for @orchidAnalyzingTraffic.
  ///
  /// In en, this message translates to:
  /// **'Orchid analyzing traffic'**
  String get orchidAnalyzingTraffic;

  /// No description provided for @vpnConnectedButNotRouting.
  ///
  /// In en, this message translates to:
  /// **'(VPN connected but not routing)'**
  String get vpnConnectedButNotRouting;

  /// No description provided for @restarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting'**
  String get restarting;

  /// No description provided for @changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly.
  ///
  /// In en, this message translates to:
  /// **'Changing monitoring status requires restarting the VPN, which may briefly interrupt privacy protection.'**
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly;

  /// No description provided for @confirmRestart.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restart'**
  String get confirmRestart;

  /// No description provided for @averagePriceIsUSDPerGb.
  ///
  /// In en, this message translates to:
  /// **'Average price is {price} USD per GB'**
  String averagePriceIsUSDPerGb(String price);

  /// No description provided for @myOrchidConfig.
  ///
  /// In en, this message translates to:
  /// **'My Orchid Config'**
  String get myOrchidConfig;

  /// No description provided for @noAccountSelected.
  ///
  /// In en, this message translates to:
  /// **'No account selected'**
  String get noAccountSelected;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tickets;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @orchidIdentity.
  ///
  /// In en, this message translates to:
  /// **'Orchid Identity'**
  String get orchidIdentity;

  /// No description provided for @addFunds.
  ///
  /// In en, this message translates to:
  /// **'ADD FUNDS'**
  String get addFunds;

  /// No description provided for @addFunds2.
  ///
  /// In en, this message translates to:
  /// **'Add Funds'**
  String get addFunds2;

  /// Gigabytes
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get gb;

  /// No description provided for @usdgb.
  ///
  /// In en, this message translates to:
  /// **'USD/GB'**
  String get usdgb;

  /// No description provided for @hop.
  ///
  /// In en, this message translates to:
  /// **'Hop'**
  String get hop;

  /// No description provided for @circuit.
  ///
  /// In en, this message translates to:
  /// **'Circuit'**
  String get circuit;

  /// No description provided for @clearAllAnalysisData.
  ///
  /// In en, this message translates to:
  /// **'Clear all analysis data?'**
  String get clearAllAnalysisData;

  /// No description provided for @thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData.
  ///
  /// In en, this message translates to:
  /// **'This action will clear all previously analyzed traffic connection data.'**
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'CLEAR ALL'**
  String get clearAll;

  /// No description provided for @stopAnalysis.
  ///
  /// In en, this message translates to:
  /// **'STOP ANALYSIS'**
  String get stopAnalysis;

  /// No description provided for @startAnalysis.
  ///
  /// In en, this message translates to:
  /// **'START ANALYSIS'**
  String get startAnalysis;

  /// No description provided for @orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre.
  ///
  /// In en, this message translates to:
  /// **'Orchid accounts include 24/7 customer support, unlimited devices and are backed by the <link2>xDai cryptocurrency</link2>.'**
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre;

  /// No description provided for @purchasedAccountsConnectExclusivelyToOur.
  ///
  /// In en, this message translates to:
  /// **'Purchased accounts connect exclusively to our <link1>preferred providers</link1>.'**
  String get purchasedAccountsConnectExclusivelyToOur;

  /// No description provided for @refundPolicyCoveredByAppStores.
  ///
  /// In en, this message translates to:
  /// **'Refund policy covered by app stores.'**
  String get refundPolicyCoveredByAppStores;

  /// No description provided for @orchidIsUnableToDisplayInappPurchasesAtThisTime.
  ///
  /// In en, this message translates to:
  /// **'Orchid is unable to display in-app purchases at this time.'**
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime;

  /// No description provided for @pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that this device supports and is configured for in-app purchases.'**
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor;

  /// No description provided for @pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that this device supports and is configured for in-app purchases or use our decentralized <link>account management</link> system.'**
  String
      get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get buy;

  /// No description provided for @gbApproximately12.
  ///
  /// In en, this message translates to:
  /// **'12GB (approximately)'**
  String get gbApproximately12;

  /// No description provided for @gbApproximately60.
  ///
  /// In en, this message translates to:
  /// **'60GB (approximately)'**
  String get gbApproximately60;

  /// No description provided for @gbApproximately240.
  ///
  /// In en, this message translates to:
  /// **'240GB (approximately)'**
  String get gbApproximately240;

  /// No description provided for @idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd.
  ///
  /// In en, this message translates to:
  /// **'Ideal size for medium-term, individual usage that includes browsing and light streaming.'**
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular!'**
  String get mostPopular;

  /// No description provided for @bandwidthheavyLongtermUsageOrSharedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth-heavy, long-term usage or shared accounts.'**
  String get bandwidthheavyLongtermUsageOrSharedAccounts;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @pausingAllTraffic.
  ///
  /// In en, this message translates to:
  /// **'Pausing all traffic...'**
  String get pausingAllTraffic;

  /// No description provided for @queryingEthereumForARandom.
  ///
  /// In en, this message translates to:
  /// **'Querying Ethereum for a random provider...'**
  String get queryingEthereumForARandom;

  /// No description provided for @quickFundAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Quick fund an account!'**
  String get quickFundAnAccount;

  /// No description provided for @accountFound.
  ///
  /// In en, this message translates to:
  /// **'Account Found'**
  String get accountFound;

  /// No description provided for @weFoundAnAccountAssociatedWithYourIdentitiesAndCreated.
  ///
  /// In en, this message translates to:
  /// **'We found an account associated with your identities and created a single hop Orchid circuit for it.  You are now ready to use the VPN.'**
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated;

  /// No description provided for @welcomeToOrchid.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Orchid!'**
  String get welcomeToOrchid;

  /// No description provided for @fundYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Fund Your Account'**
  String get fundYourAccount;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService.
  ///
  /// In en, this message translates to:
  /// **'Subscription-free, pay as you go, decentralized, open source VPN service.'**
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService;

  /// No description provided for @getStartedFor1.
  ///
  /// In en, this message translates to:
  /// **'GET STARTED FOR {smallAmount}'**
  String getStartedFor1(String smallAmount);

  /// No description provided for @importAccount.
  ///
  /// In en, this message translates to:
  /// **'Import Account'**
  String get importAccount;

  /// No description provided for @illDoThisLater.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do this later'**
  String get illDoThisLater;

  /// No description provided for @connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By.
  ///
  /// In en, this message translates to:
  /// **'Connect automatically to one of the network’s <link1>preferred providers</link1> by purchasing VPN credits to fund your shareable, refillable Orchid account.'**
  String
      get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By;

  /// No description provided for @confirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PURCHASE'**
  String get confirmPurchase;

  /// No description provided for @orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink.
  ///
  /// In en, this message translates to:
  /// **'Orchid accounts use VPN credits backed by the <link>xDAI cryptocurrency</link>, include 24/7 customer support, unlimited device sharing and are covered by app store refund policies.'**
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink;

  /// No description provided for @yourPurchaseIsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is in progress.'**
  String get yourPurchaseIsInProgress;

  /// No description provided for @thisPurchaseIsTakingLongerThanExpectedToProcessAnd.
  ///
  /// In en, this message translates to:
  /// **'This purchase is taking longer than expected to process and may have encountered an error.'**
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd;

  /// No description provided for @thisMayTakeAMinute.
  ///
  /// In en, this message translates to:
  /// **'This may take a minute...'**
  String get thisMayTakeAMinute;

  /// No description provided for @vpnCredits.
  ///
  /// In en, this message translates to:
  /// **'VPN Credits'**
  String get vpnCredits;

  /// No description provided for @blockchainFee.
  ///
  /// In en, this message translates to:
  /// **'Blockchain fee'**
  String get blockchainFee;

  /// No description provided for @promotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotion;

  /// No description provided for @showInAccountManager.
  ///
  /// In en, this message translates to:
  /// **'Show in Account Manager'**
  String get showInAccountManager;

  /// No description provided for @deleteThisOrchidIdentity.
  ///
  /// In en, this message translates to:
  /// **'Delete this Orchid Identity'**
  String get deleteThisOrchidIdentity;

  /// No description provided for @chooseIdentity.
  ///
  /// In en, this message translates to:
  /// **'Choose Identity'**
  String get chooseIdentity;

  /// No description provided for @updatingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Updating Accounts'**
  String get updatingAccounts;

  /// No description provided for @trafficAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Traffic Analysis'**
  String get trafficAnalysis;

  /// No description provided for @accountManager.
  ///
  /// In en, this message translates to:
  /// **'Account Manager'**
  String get accountManager;

  /// No description provided for @circuitBuilder.
  ///
  /// In en, this message translates to:
  /// **'Circuit Builder'**
  String get circuitBuilder;

  /// No description provided for @exitHop.
  ///
  /// In en, this message translates to:
  /// **'Exit Hop'**
  String get exitHop;

  /// No description provided for @entryHop.
  ///
  /// In en, this message translates to:
  /// **'Entry Hop'**
  String get entryHop;

  /// No description provided for @addNewHop.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW HOP'**
  String get addNewHop;

  /// No description provided for @newCircuitBuilder.
  ///
  /// In en, this message translates to:
  /// **'New circuit builder!'**
  String get newCircuitBuilder;

  /// No description provided for @youCanNowPayForAMultihopOrchidCircuitWith.
  ///
  /// In en, this message translates to:
  /// **'You can now pay for a multi-hop Orchid circuit with xDAI. The multihop interface now supports xDAI and OXT Orchid accounts and still supports OpenVPN and WireGuard configs that can be strung together into an onion route.'**
  String get youCanNowPayForAMultihopOrchidCircuitWith;

  /// No description provided for @manageYourConnectionFromTheCircuitBuilderInsteadOfThe.
  ///
  /// In en, this message translates to:
  /// **'Manage your connection from the circuit builder instead of the account manager. All connections now use a circuit with zero or more hops. Any existing configuration has been migrated to the circuit builder.'**
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe;

  /// No description provided for @quickStartFor1.
  ///
  /// In en, this message translates to:
  /// **'Quick start for {smallAmount}'**
  String quickStartFor1(String smallAmount);

  /// No description provided for @weAddedAMethodToPurchaseAnOrchidAccountAnd.
  ///
  /// In en, this message translates to:
  /// **'We added a method to purchase an Orchid account and create a single hop circuit from the homescreen to shortcut the onboarding process.'**
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd;

  /// No description provided for @orchidIsUniqueAsAMultiHopOrOnion.
  ///
  /// In en, this message translates to:
  /// **'Orchid is unique as a multi-hop or onion routing client supporting multiple VPN protocols. You can set up your connection by chaining together hops from the supported protocols below.\n\nOne hop is like a regular VPN. Three hops (for advanced users) is the classic onion routing choice.  Zero hops allows traffic analysis without any VPN tunnel.'**
  String get orchidIsUniqueAsAMultiHopOrOnion;

  /// No description provided for @deletingOpenVPNAndWireguardHopsWillLose.
  ///
  /// In en, this message translates to:
  /// **'Deleting OpenVPN and Wireguard hops will lose any associated credentials and connection configuration. Be sure to back up any information before continuing.'**
  String get deletingOpenVPNAndWireguardHopsWillLose;

  /// No description provided for @thisCannotBeUndoneToSaveThisIdentity.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.  To save this identity hit cancel and use the Export option'**
  String get thisCannotBeUndoneToSaveThisIdentity;

  /// No description provided for @unlockTime.
  ///
  /// In en, this message translates to:
  /// **'Unlock Time'**
  String get unlockTime;

  /// No description provided for @chooseChain.
  ///
  /// In en, this message translates to:
  /// **'Choose Chain'**
  String get chooseChain;

  /// No description provided for @unlocking.
  ///
  /// In en, this message translates to:
  /// **'Unlocking'**
  String get unlocking;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @orchidTransaction.
  ///
  /// In en, this message translates to:
  /// **'Orchid Transaction'**
  String get orchidTransaction;

  /// No description provided for @confirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get confirmations;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending...'**
  String get pending;

  /// No description provided for @txHash.
  ///
  /// In en, this message translates to:
  /// **'Tx Hash:'**
  String get txHash;

  /// No description provided for @allOfYourFundsAreAvailableForWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'All of your funds are available for withdrawal.'**
  String get allOfYourFundsAreAvailableForWithdrawal;

  /// No description provided for @maxWithdrawOfYourTotalFundsCombinedFunds.
  ///
  /// In en, this message translates to:
  /// **'{maxWithdraw} of your {totalFunds} combined funds are currently available for withdrawal.'**
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds);

  /// No description provided for @alsoUnlockRemainingDeposit.
  ///
  /// In en, this message translates to:
  /// **'Also unlock remaining deposit'**
  String get alsoUnlockRemainingDeposit;

  /// No description provided for @ifYouSpecifyLessThanTheFullAmountFundsWill.
  ///
  /// In en, this message translates to:
  /// **'If you specify less than the full amount funds will be drawn from your balance first.'**
  String get ifYouSpecifyLessThanTheFullAmountFundsWill;

  /// No description provided for @forAdditionalOptionsSeeTheAdvancedPanel.
  ///
  /// In en, this message translates to:
  /// **'For additional options see the ADVANCED panel.'**
  String get forAdditionalOptionsSeeTheAdvancedPanel;

  /// No description provided for @ifYouSelectTheUnlockDepositOptionThisTransactionWill.
  ///
  /// In en, this message translates to:
  /// **'If you select the unlock deposit option this transaction will immediately withdraw the specified amount from your balance and also begin the unlock process for your remaining deposit.'**
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill;

  /// No description provided for @depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking.
  ///
  /// In en, this message translates to:
  /// **'Deposit funds are available for withdrawal 24 hours after unlocking.'**
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking;

  /// No description provided for @withdrawFundsFromYourOrchidAccountToYourCurrentWallet.
  ///
  /// In en, this message translates to:
  /// **'Withdraw funds from your Orchid Account to your current wallet.'**
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet;

  /// No description provided for @withdrawAndUnlockFunds.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW AND UNLOCK FUNDS'**
  String get withdrawAndUnlockFunds;

  /// No description provided for @withdrawFunds.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW FUNDS'**
  String get withdrawFunds;

  /// No description provided for @withdrawFunds2.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawFunds2;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @submitTransaction.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT TRANSACTION'**
  String get submitTransaction;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get add;

  /// No description provided for @balanceToDeposit.
  ///
  /// In en, this message translates to:
  /// **'BALANCE TO DEPOSIT'**
  String get balanceToDeposit;

  /// No description provided for @depositToBalance.
  ///
  /// In en, this message translates to:
  /// **'DEPOSIT TO BALANCE'**
  String get depositToBalance;

  /// No description provided for @setWarnedAmount.
  ///
  /// In en, this message translates to:
  /// **'Set Warned Amount'**
  String get setWarnedAmount;

  /// No description provided for @addFundsToYourOrchidAccountBalanceAndorDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add funds to your Orchid Account balance and/or deposit.'**
  String get addFundsToYourOrchidAccountBalanceAndorDeposit;

  /// No description provided for @forGuidanceOnSizingYourAccountSee.
  ///
  /// In en, this message translates to:
  /// **'For guidance on sizing your account see <link>orchid.com</link>'**
  String get forGuidanceOnSizingYourAccountSee;

  /// No description provided for @currentTokenPreauthorizationAmount.
  ///
  /// In en, this message translates to:
  /// **'Current {tokenType} pre-authorization: {amount}'**
  String currentTokenPreauthorizationAmount(String tokenType, String amount);

  /// No description provided for @noWallet.
  ///
  /// In en, this message translates to:
  /// **'No Wallet'**
  String get noWallet;

  /// No description provided for @noWalletOrBrowserNotSupported.
  ///
  /// In en, this message translates to:
  /// **'No Wallet or Browser not supported.'**
  String get noWalletOrBrowserNotSupported;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @failedToConnectToWalletconnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to WalletConnect.'**
  String get failedToConnectToWalletconnect;

  /// No description provided for @unknownChain.
  ///
  /// In en, this message translates to:
  /// **'Unknown Chain'**
  String get unknownChain;

  /// No description provided for @theOrchidAccountManagerDoesntSupportThisChainYet.
  ///
  /// In en, this message translates to:
  /// **'The Orchid Account Manager doesn\'t support this chain yet.'**
  String get theOrchidAccountManagerDoesntSupportThisChainYet;

  /// No description provided for @orchidIsntOnThisChain.
  ///
  /// In en, this message translates to:
  /// **'Orchid isn\'t on this chain.'**
  String get orchidIsntOnThisChain;

  /// No description provided for @theOrchidContractHasntBeenDeployedOnThisChainYet.
  ///
  /// In en, this message translates to:
  /// **'The Orchid contract hasn\'t been deployed on this chain yet.'**
  String get theOrchidContractHasntBeenDeployedOnThisChainYet;

  /// No description provided for @moveFunds.
  ///
  /// In en, this message translates to:
  /// **'MOVE FUNDS'**
  String get moveFunds;

  /// No description provided for @moveFunds2.
  ///
  /// In en, this message translates to:
  /// **'Move Funds'**
  String get moveFunds2;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'LOCK / UNLOCK'**
  String get lockUnlock;

  /// No description provided for @yourDepositOfAmountIsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Your deposit of {amount} is unlocked.'**
  String yourDepositOfAmountIsUnlocked(String amount);

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get locked;

  /// No description provided for @yourDepositOfAmountIsUnlockingOrUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Your deposit of {amount} is {unlockingOrUnlocked}.'**
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked);

  /// No description provided for @theFundsWillBeAvailableForWithdrawalInTime.
  ///
  /// In en, this message translates to:
  /// **'The funds will be available for withdrawal in {time}.'**
  String theFundsWillBeAvailableForWithdrawalInTime(String time);

  /// No description provided for @lockDeposit.
  ///
  /// In en, this message translates to:
  /// **'LOCK DEPOSIT'**
  String get lockDeposit;

  /// No description provided for @unlockDeposit.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK DEPOSIT'**
  String get unlockDeposit;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED'**
  String get advanced;

  /// No description provided for @linklearnMoreAboutOrchidAccountslink.
  ///
  /// In en, this message translates to:
  /// **'<link>Learn more about Orchid Accounts</link>.'**
  String get linklearnMoreAboutOrchidAccountslink;

  /// No description provided for @estimatedCostToCreateAnOrchidAccountWith.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost to create an Orchid Account with an efficiency of {efficiency} and {num} tickets of value.'**
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num);

  /// No description provided for @chain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get chain;

  /// No description provided for @token.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get token;

  /// No description provided for @minDeposit.
  ///
  /// In en, this message translates to:
  /// **'Min Deposit'**
  String get minDeposit;

  /// No description provided for @minBalance.
  ///
  /// In en, this message translates to:
  /// **'Min Balance'**
  String get minBalance;

  /// No description provided for @fundFee.
  ///
  /// In en, this message translates to:
  /// **'Fund Fee'**
  String get fundFee;

  /// No description provided for @withdrawFee.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Fee'**
  String get withdrawFee;

  /// No description provided for @tokenValues.
  ///
  /// In en, this message translates to:
  /// **'TOKEN VALUES'**
  String get tokenValues;

  /// No description provided for @usdPrices.
  ///
  /// In en, this message translates to:
  /// **'USD PRICES'**
  String get usdPrices;

  /// No description provided for @settingAWarnedDepositAmountBeginsThe24HourWaiting.
  ///
  /// In en, this message translates to:
  /// **'Setting a warned deposit amount begins the 24 hour waiting period required to withdraw deposit funds.'**
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting;

  /// No description provided for @duringThisPeriodTheFundsAreNotAvailableAsA.
  ///
  /// In en, this message translates to:
  /// **'During this period the funds are not available as a valid deposit on the Orchid network.'**
  String get duringThisPeriodTheFundsAreNotAvailableAsA;

  /// No description provided for @fundsMayBeRelockedAtAnyTimeByReducingThe.
  ///
  /// In en, this message translates to:
  /// **'Funds may be re-locked at any time by reducing the warned amount.'**
  String get fundsMayBeRelockedAtAnyTimeByReducingThe;

  /// No description provided for @warn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get warn;

  /// No description provided for @totalWarnedAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Warned Amount'**
  String get totalWarnedAmount;

  /// No description provided for @newIdentity.
  ///
  /// In en, this message translates to:
  /// **'New Identity'**
  String get newIdentity;

  /// No description provided for @importIdentity.
  ///
  /// In en, this message translates to:
  /// **'Import Identity'**
  String get importIdentity;

  /// No description provided for @exportIdentity.
  ///
  /// In en, this message translates to:
  /// **'Export Identity'**
  String get exportIdentity;

  /// No description provided for @deleteIdentity.
  ///
  /// In en, this message translates to:
  /// **'Delete Identity'**
  String get deleteIdentity;

  /// No description provided for @importOrchidIdentity.
  ///
  /// In en, this message translates to:
  /// **'Import Orchid Identity'**
  String get importOrchidIdentity;

  /// No description provided for @funderAddress.
  ///
  /// In en, this message translates to:
  /// **'Funder Address'**
  String get funderAddress;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @txFee.
  ///
  /// In en, this message translates to:
  /// **'Tx Fee'**
  String get txFee;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @rpc.
  ///
  /// In en, this message translates to:
  /// **'RPC'**
  String get rpc;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @lastHour.
  ///
  /// In en, this message translates to:
  /// **'Last Hour'**
  String get lastHour;

  /// No description provided for @chainSettings.
  ///
  /// In en, this message translates to:
  /// **'Chain Settings'**
  String get chainSettings;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @fetchGasPrice.
  ///
  /// In en, this message translates to:
  /// **'Fetch gas price'**
  String get fetchGasPrice;

  /// No description provided for @fetchLotteryPot.
  ///
  /// In en, this message translates to:
  /// **'Fetch lottery pot'**
  String get fetchLotteryPot;

  /// No description provided for @lines.
  ///
  /// In en, this message translates to:
  /// **'lines'**
  String get lines;

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'filtered'**
  String get filtered;

  /// No description provided for @backUpYourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Back up your Identity'**
  String get backUpYourIdentity;

  /// No description provided for @accountSetUp.
  ///
  /// In en, this message translates to:
  /// **'Account set up'**
  String get accountSetUp;

  /// No description provided for @setUpAccount.
  ///
  /// In en, this message translates to:
  /// **'SET UP ACCOUNT'**
  String get setUpAccount;

  /// No description provided for @generateIdentity.
  ///
  /// In en, this message translates to:
  /// **'GENERATE IDENTITY'**
  String get generateIdentity;

  /// No description provided for @enterAnExistingOrchidIdentity.
  ///
  /// In en, this message translates to:
  /// **'Enter an existing <account_link>Orchid Identity</account_link>'**
  String get enterAnExistingOrchidIdentity;

  /// No description provided for @pasteTheWeb3WalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Paste the web3 wallet address that you will use to fund your account below.'**
  String get pasteTheWeb3WalletAddress;

  /// No description provided for @funderWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Funder wallet address'**
  String get funderWalletAddress;

  /// No description provided for @yourOrchidIdentityPublicAddress.
  ///
  /// In en, this message translates to:
  /// **'Your Orchid Identity public address'**
  String get yourOrchidIdentityPublicAddress;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueButton;

  /// No description provided for @yesIHaveSavedACopyOf.
  ///
  /// In en, this message translates to:
  /// **'Yes, I have saved a copy of my private key somewhere secure.'**
  String get yesIHaveSavedACopyOf;

  /// No description provided for @backUpYourOrchidIdentityPrivateKeyYouWill.
  ///
  /// In en, this message translates to:
  /// **'Back up your Orchid Identity <bold>private key</bold>. You will need this key to share, import or restore this identity and all associated accounts.'**
  String get backUpYourOrchidIdentityPrivateKeyYouWill;

  /// No description provided for @locked1.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked1;

  /// No description provided for @unlockDeposit1.
  ///
  /// In en, this message translates to:
  /// **'Unlock deposit'**
  String get unlockDeposit1;

  /// No description provided for @changeWarnedAmountTo.
  ///
  /// In en, this message translates to:
  /// **'Change Warned Amount To'**
  String get changeWarnedAmountTo;

  /// No description provided for @setWarnedAmountTo.
  ///
  /// In en, this message translates to:
  /// **'Set Warned Amount To'**
  String get setWarnedAmountTo;

  /// No description provided for @currentWarnedAmount.
  ///
  /// In en, this message translates to:
  /// **'Current Warned Amount'**
  String get currentWarnedAmount;

  /// No description provided for @allWarnedFundsWillBeLockedUntil.
  ///
  /// In en, this message translates to:
  /// **'All warned funds will be locked until'**
  String get allWarnedFundsWillBeLockedUntil;

  /// No description provided for @balanceToDeposit1.
  ///
  /// In en, this message translates to:
  /// **'Balance to Deposit'**
  String get balanceToDeposit1;

  /// No description provided for @depositToBalance1.
  ///
  /// In en, this message translates to:
  /// **'Deposit to Balance'**
  String get depositToBalance1;

  /// No description provided for @advanced1.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced1;

  /// No description provided for @add1.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add1;

  /// No description provided for @lockUnlock1.
  ///
  /// In en, this message translates to:
  /// **'Lock / Unlock'**
  String get lockUnlock1;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogs;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @identiconStyle.
  ///
  /// In en, this message translates to:
  /// **'Identicon Style'**
  String get identiconStyle;

  /// No description provided for @blockies.
  ///
  /// In en, this message translates to:
  /// **'Blockies'**
  String get blockies;

  /// No description provided for @jazzicon.
  ///
  /// In en, this message translates to:
  /// **'Jazzicon'**
  String get jazzicon;

  /// No description provided for @contractVersion.
  ///
  /// In en, this message translates to:
  /// **'Contract Version'**
  String get contractVersion;

  /// No description provided for @version0.
  ///
  /// In en, this message translates to:
  /// **'Version 0'**
  String get version0;

  /// No description provided for @version1.
  ///
  /// In en, this message translates to:
  /// **'Version 1'**
  String get version1;

  /// No description provided for @connectedWithMetamask.
  ///
  /// In en, this message translates to:
  /// **'Connected with Metamask'**
  String get connectedWithMetamask;

  /// No description provided for @blockExplorer.
  ///
  /// In en, this message translates to:
  /// **'Block Explorer'**
  String get blockExplorer;

  /// No description provided for @tapToMinimize.
  ///
  /// In en, this message translates to:
  /// **'Tap to Minimize'**
  String get tapToMinimize;

  /// No description provided for @connectWallet.
  ///
  /// In en, this message translates to:
  /// **'CONNECT WALLET'**
  String get connectWallet;

  /// No description provided for @checkWallet.
  ///
  /// In en, this message translates to:
  /// **'Check Wallet'**
  String get checkWallet;

  /// No description provided for @checkYourWalletAppOrExtensionFor.
  ///
  /// In en, this message translates to:
  /// **'Check your Wallet app or extension for a pending request.'**
  String get checkYourWalletAppOrExtensionFor;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @chainName.
  ///
  /// In en, this message translates to:
  /// **'Chain name'**
  String get chainName;

  /// No description provided for @rpcUrl.
  ///
  /// In en, this message translates to:
  /// **'RPC Url'**
  String get rpcUrl;

  /// No description provided for @tokenPrice.
  ///
  /// In en, this message translates to:
  /// **'Token Price'**
  String get tokenPrice;

  /// No description provided for @tokenPriceUsd.
  ///
  /// In en, this message translates to:
  /// **'Token Price USD'**
  String get tokenPriceUsd;

  /// No description provided for @addChain.
  ///
  /// In en, this message translates to:
  /// **'Add Chain'**
  String get addChain;

  /// No description provided for @deleteChainQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Chain?'**
  String get deleteChainQuestion;

  /// No description provided for @deleteUserConfiguredChain.
  ///
  /// In en, this message translates to:
  /// **'Delete user-configured chain'**
  String get deleteUserConfiguredChain;

  /// No description provided for @fundContractDeployer.
  ///
  /// In en, this message translates to:
  /// **'Fund Contract Deployer'**
  String get fundContractDeployer;

  /// No description provided for @deploySingletonFactory.
  ///
  /// In en, this message translates to:
  /// **'Deploy Singleton Factory'**
  String get deploySingletonFactory;

  /// No description provided for @deployContract.
  ///
  /// In en, this message translates to:
  /// **'Deploy Contract'**
  String get deployContract;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @dappVersion.
  ///
  /// In en, this message translates to:
  /// **'Dapp Version'**
  String get dappVersion;

  /// No description provided for @viewContractOnEtherscan.
  ///
  /// In en, this message translates to:
  /// **'View Contract on Etherscan'**
  String get viewContractOnEtherscan;

  /// No description provided for @viewContractOnGithub.
  ///
  /// In en, this message translates to:
  /// **'View Contract on Github'**
  String get viewContractOnGithub;

  /// No description provided for @accountChanges.
  ///
  /// In en, this message translates to:
  /// **'Account Changes'**
  String get accountChanges;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @step1.
  ///
  /// In en, this message translates to:
  /// **'<bold>Step 1.</bold> Connect an ERC-20 wallet with <link>enough tokens</link> in it.'**
  String get step1;

  /// No description provided for @step2.
  ///
  /// In en, this message translates to:
  /// **'<bold>Step 2.</bold> Copy the Orchid Identity from the Orchid App by going to Manage Accounts then tapping the address.'**
  String get step2;

  /// No description provided for @connectOrCreate.
  ///
  /// In en, this message translates to:
  /// **'Connect or create Orchid Account'**
  String get connectOrCreate;

  /// No description provided for @lockDeposit2.
  ///
  /// In en, this message translates to:
  /// **'Lock Deposit'**
  String get lockDeposit2;

  /// No description provided for @unlockDeposit2.
  ///
  /// In en, this message translates to:
  /// **'Unlock Deposit'**
  String get unlockDeposit2;

  /// No description provided for @enterYourWeb3.
  ///
  /// In en, this message translates to:
  /// **'Enter your web3 wallet address.'**
  String get enterYourWeb3;

  /// No description provided for @purchaseComplete.
  ///
  /// In en, this message translates to:
  /// **'Purchase Complete'**
  String get purchaseComplete;

  /// No description provided for @generateNewIdentity.
  ///
  /// In en, this message translates to:
  /// **'Generate a new Identity'**
  String get generateNewIdentity;

  /// No description provided for @copyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Copy Identity'**
  String get copyIdentity;

  /// No description provided for @yourPurchaseIsComplete.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is complete and is now being processed by the xDai blockchain, which could take a few minutes.  A default circuit has been generated for you using this account. You can monitor the available balance on the home screen or in the account manager.'**
  String get yourPurchaseIsComplete;

  /// No description provided for @circuitGenerated.
  ///
  /// In en, this message translates to:
  /// **'Circuit Generated'**
  String get circuitGenerated;

  /// No description provided for @usingYourOrchidAccount.
  ///
  /// In en, this message translates to:
  /// **'Using your Orchid account, a single hop circuit has been generated. You may manage this from the circuit builder screen.'**
  String get usingYourOrchidAccount;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'en',
        'es',
        'fr',
        'hi',
        'id',
        'it',
        'ja',
        'ko',
        'pt',
        'ru',
        'tr',
        'uk',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return SPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'es':
      return SEs();
    case 'fr':
      return SFr();
    case 'hi':
      return SHi();
    case 'id':
      return SId();
    case 'it':
      return SIt();
    case 'ja':
      return SJa();
    case 'ko':
      return SKo();
    case 'pt':
      return SPt();
    case 'ru':
      return SRu();
    case 'tr':
      return STr();
    case 'uk':
      return SUk();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
