// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

class S {
  S(this.localeName);
  
  static const AppLocalizationDelegate delegate =
    AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final String name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return S(localeName);
    });
  } 

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  final String localeName;

  String get newHop {
    return Intl.message(
      'New Hop',
      name: 'newHop',
      desc: 'New network hop',
      args: [],
    );
  }

  String get orchidHop {
    return Intl.message(
      'Orchid Hop',
      name: 'orchidHop',
      desc: 'Orchid network hop',
      args: [],
    );
  }

  String get orchidDisabled {
    return Intl.message(
      'Orchid disabled',
      name: 'orchidDisabled',
      desc: '',
      args: [],
    );
  }

  String get trafficMonitoringOnly {
    return Intl.message(
      'Traffic monitoring only',
      name: 'trafficMonitoringOnly',
      desc: '',
      args: [],
    );
  }

  String get orchidConnecting {
    return Intl.message(
      'Orchid connecting',
      name: 'orchidConnecting',
      desc: '',
      args: [],
    );
  }

  String get orchidDisconnecting {
    return Intl.message(
      'Orchid disconnecting',
      name: 'orchidDisconnecting',
      desc: '',
      args: [],
    );
  }

  String numHopsConfigured(dynamic num) {
    return Intl.plural(
      num,
      zero: 'No hops configured',
      one: 'One hop configured',
      two: 'Two hops configured',
      other: '$num hops configured',
      name: 'numHopsConfigured',
      desc: '',
      args: [num],
    );
  }

  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  String get turnOnToActivate {
    return Intl.message(
      'Turn Orchid on to activate your hops and protect your traffic',
      name: 'turnOnToActivate',
      desc: '',
      args: [],
    );
  }

  String get createFirstHop {
    return Intl.message(
      'Create your first hop to protect your connection.',
      name: 'createFirstHop',
      desc: '',
      args: [],
    );
  }

  String get orchid {
    return Intl.message(
      'Orchid',
      name: 'orchid',
      desc: '',
      args: [],
    );
  }

  String get openVPN {
    return Intl.message(
      'OpenVPN',
      name: 'openVPN',
      desc: '',
      args: [],
    );
  }

  String get status {
    return Intl.message(
      'Status',
      name: 'status',
      desc: '',
      args: [],
    );
  }

  String get hops {
    return Intl.message(
      'Hops',
      name: 'hops',
      desc: 'Network hops',
      args: [],
    );
  }

  String get traffic {
    return Intl.message(
      'Traffic',
      name: 'traffic',
      desc: 'Network traffic',
      args: [],
    );
  }

  String get createInstruction1 {
    return Intl.message(
      'To create an Orchid hop you need an Orchid account.  Open',
      name: 'createInstruction1',
      desc: '',
      args: [],
    );
  }

  String get createInstructions2 {
    return Intl.message(
      'in a Web3 browser and follow the steps.  Paste in your Ethereum address below.',
      name: 'createInstructions2',
      desc: '',
      args: [],
    );
  }

  String get learnMoreButtonTitle {
    return Intl.message(
      'LEARN MORE',
      name: 'learnMoreButtonTitle',
      desc: '',
      args: [],
    );
  }

  String get orchidRequiresOXT {
    return Intl.message(
      'Orchid requires OXT',
      name: 'orchidRequiresOXT',
      desc: '',
      args: [],
    );
  }

  String get credentials {
    return Intl.message(
      'Credentials',
      name: 'credentials',
      desc: '',
      args: [],
    );
  }

  String get curation {
    return Intl.message(
      'Curation',
      name: 'curation',
      desc: '',
      args: [],
    );
  }

  String get rateLimit {
    return Intl.message(
      'Rate Limit',
      name: 'rateLimit',
      desc: '',
      args: [],
    );
  }

  String get signerKey {
    return Intl.message(
      'Signer Key',
      name: 'signerKey',
      desc: '',
      args: [],
    );
  }

  String get copy {
    return Intl.message(
      'Copy',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  String get paste {
    return Intl.message(
      'Paste',
      name: 'paste',
      desc: '',
      args: [],
    );
  }

  String get ethereumAddress {
    return Intl.message(
      'Ethereum Address',
      name: 'ethereumAddress',
      desc: '',
      args: [],
    );
  }

  String get oxt {
    return Intl.message(
      'OXT',
      name: 'oxt',
      desc: '',
      args: [],
    );
  }

  String get amount {
    return Intl.message(
      'Amount',
      name: 'amount',
      desc: '',
      args: [],
    );
  }

  String get deposit {
    return Intl.message(
      'Deposit',
      name: 'deposit',
      desc: '',
      args: [],
    );
  }

  String get curator {
    return Intl.message(
      'Curator',
      name: 'curator',
      desc: '',
      args: [],
    );
  }

  String get viewOrModifyRateLimit {
    return Intl.message(
      'View or modify your rate limit.',
      name: 'viewOrModifyRateLimit',
      desc: '',
      args: [],
    );
  }

  String get shareOrchidAccount {
    return Intl.message(
      'Share Orchid Account',
      name: 'shareOrchidAccount',
      desc: '',
      args: [],
    );
  }

  String get myOrchidAccount {
    return Intl.message(
      'My Orchid Account',
      name: 'myOrchidAccount',
      desc: '',
      args: [],
    );
  }

  String get budget {
    return Intl.message(
      'Budget',
      name: 'budget',
      desc: '',
      args: [],
    );
  }

  String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  String get settingsButtonTitle {
    return Intl.message(
      'SETTINGS',
      name: 'settingsButtonTitle',
      desc: '',
      args: [],
    );
  }

  String get confirmThisAction {
    return Intl.message(
      'Confirm this action',
      name: 'confirmThisAction',
      desc: '',
      args: [],
    );
  }

  String get cancelButtonTitle {
    return Intl.message(
      'CANCEL',
      name: 'cancelButtonTitle',
      desc: '',
      args: [],
    );
  }

  String get changesWillTakeEffectInstruction {
    return Intl.message(
      'Changes will take effect when the VPN is restarted.',
      name: 'changesWillTakeEffectInstruction',
      desc: '',
      args: [],
    );
  }

  String get saved {
    return Intl.message(
      'Saved',
      name: 'saved',
      desc: '',
      args: [],
    );
  }

  String get configurationSaved {
    return Intl.message(
      'Configuration saved',
      name: 'configurationSaved',
      desc: '',
      args: [],
    );
  }

  String get whoops {
    return Intl.message(
      'Whoops',
      name: 'whoops',
      desc: '',
      args: [],
    );
  }

  String get configurationFailedInstruction {
    return Intl.message(
      'Configuration failed to save.  Please check syntax and try again.',
      name: 'configurationFailedInstruction',
      desc: '',
      args: [],
    );
  }

  String get addHop {
    return Intl.message(
      'Add Hop',
      name: 'addHop',
      desc: '',
      args: [],
    );
  }

  String get selectYourHop {
    return Intl.message(
      'Select your hop',
      name: 'selectYourHop',
      desc: '',
      args: [],
    );
  }

  String get iHaveAQRCode {
    return Intl.message(
      'I have a QR code',
      name: 'iHaveAQRCode',
      desc: '',
      args: [],
    );
  }

  String get purchasePAC {
    return Intl.message(
      'Purchase an Account (PAC)',
      name: 'purchasePAC',
      desc: '',
      args: [],
    );
  }

  String get iWantToTryOrchid {
    return Intl.message(
      'I want to try Orchid',
      name: 'iWantToTryOrchid',
      desc: '',
      args: [],
    );
  }

  String get iHaveOrchidAccount {
    return Intl.message(
      'I have an Orchid Account',
      name: 'iHaveOrchidAccount',
      desc: '',
      args: [],
    );
  }

  String get iHaveAVPNSubscription {
    return Intl.message(
      'I have a VPN subscription',
      name: 'iHaveAVPNSubscription',
      desc: '',
      args: [],
    );
  }

  String get orchidRequiresAccountInstruction {
    return Intl.message(
      'Orchid requires an Orchid account.  Scan or paste your existing account below to get started.',
      name: 'orchidRequiresAccountInstruction',
      desc: '',
      args: [],
    );
  }

  String get createOrchidAccount {
    return Intl.message(
      'Create Orchid Account',
      name: 'createOrchidAccount',
      desc: '',
      args: [],
    );
  }

  String get youNeedEthereumWallet {
    return Intl.message(
      'You\'ll need an Ethereum Wallet in order to create an Orchid account.',
      name: 'youNeedEthereumWallet',
      desc: '',
      args: [],
    );
  }

  String get loadMsg {
    return Intl.message(
      'Load',
      name: 'loadMsg',
      desc: '',
      args: [],
    );
  }

  String get inYourWalletBrowserInstruction {
    return Intl.message(
      'in your wallet\'s browser to get started.',
      name: 'inYourWalletBrowserInstruction',
      desc: '',
      args: [],
    );
  }

  String get needMoreHelp {
    return Intl.message(
      'Need more help',
      name: 'needMoreHelp',
      desc: '',
      args: [],
    );
  }

  String get readTheGuide {
    return Intl.message(
      'Read the guide',
      name: 'readTheGuide',
      desc: '',
      args: [],
    );
  }

  String get addOrchidAccount {
    return Intl.message(
      'Add Orchid Account',
      name: 'addOrchidAccount',
      desc: '',
      args: [],
    );
  }

  String get addAccount {
    return Intl.message(
      'Add Account',
      name: 'addAccount',
      desc: '',
      args: [],
    );
  }

  String get scan {
    return Intl.message(
      'Scan',
      name: 'scan',
      desc: '',
      args: [],
    );
  }

  String get invalidQRCode {
    return Intl.message(
      'Invalid QR Code',
      name: 'invalidQRCode',
      desc: '',
      args: [],
    );
  }

  String get theQRCodeYouScannedDoesNot {
    return Intl.message(
      'The QR code you scanned does not contain a valid account configuration.',
      name: 'theQRCodeYouScannedDoesNot',
      desc: '',
      args: [],
    );
  }

  String get invalidCode {
    return Intl.message(
      'Invalid Code',
      name: 'invalidCode',
      desc: '',
      args: [],
    );
  }

  String get theCodeYouPastedDoesNot {
    return Intl.message(
      'The code you pasted does not contain a valid account configuration.',
      name: 'theCodeYouPastedDoesNot',
      desc: '',
      args: [],
    );
  }

  String get openVPNHop {
    return Intl.message(
      'OpenVPN Hop',
      name: 'openVPNHop',
      desc: '',
      args: [],
    );
  }

  String get username {
    return Intl.message(
      'Username',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  String get config {
    return Intl.message(
      'Config',
      name: 'config',
      desc: '',
      args: [],
    );
  }

  String get pasteYourOVPN {
    return Intl.message(
      'Paste your OVPN config file here',
      name: 'pasteYourOVPN',
      desc: '',
      args: [],
    );
  }

  String get enterYourCredentials {
    return Intl.message(
      'Enter your credentials',
      name: 'enterYourCredentials',
      desc: '',
      args: [],
    );
  }

  String get enterLoginInformationInstruction {
    return Intl.message(
      'Enter the login information for your VPN provider above. Then paste the contents of your provider’s OpenVPN config file into the field provided.',
      name: 'enterLoginInformationInstruction',
      desc: '',
      args: [],
    );
  }

  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  String get help {
    return Intl.message(
      'Help',
      name: 'help',
      desc: '',
      args: [],
    );
  }

  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  String get openSourceLicenses {
    return Intl.message(
      'Open Source Licenses',
      name: 'openSourceLicenses',
      desc: '',
      args: [],
    );
  }

  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  String get advanced {
    return Intl.message(
      'Advanced',
      name: 'advanced',
      desc: '',
      args: [],
    );
  }

  String get version {
    return Intl.message(
      'Version',
      name: 'version',
      desc: '',
      args: [],
    );
  }

  String get noVersion {
    return Intl.message(
      'No version',
      name: 'noVersion',
      desc: '',
      args: [],
    );
  }

  String get setup {
    return Intl.message(
      'Setup',
      name: 'setup',
      desc: '',
      args: [],
    );
  }

  String get orchidOverview {
    return Intl.message(
      'Orchid Overview',
      name: 'orchidOverview',
      desc: '',
      args: [],
    );
  }

  String get log {
    return Intl.message(
      'Log',
      name: 'log',
      desc: '',
      args: [],
    );
  }

  String get defaultCurator {
    return Intl.message(
      'Default Curator',
      name: 'defaultCurator',
      desc: '',
      args: [],
    );
  }

  String get allowNoHopVPN {
    return Intl.message(
      'Allow No Hop VPN',
      name: 'allowNoHopVPN',
      desc: '',
      args: [],
    );
  }

  String get queryBalances {
    return Intl.message(
      'Query Balances',
      name: 'queryBalances',
      desc: '',
      args: [],
    );
  }

  String get showInstructions {
    return Intl.message(
      'Show Instructions',
      name: 'showInstructions',
      desc: '',
      args: [],
    );
  }

  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  String get manageConfiguration {
    return Intl.message(
      'Manage Configuration',
      name: 'manageConfiguration',
      desc: '',
      args: [],
    );
  }

  String get showStatusPage {
    return Intl.message(
      'Show Status Page',
      name: 'showStatusPage',
      desc: '',
      args: [],
    );
  }

  String get beta {
    return Intl.message(
      'beta',
      name: 'beta',
      desc: '',
      args: [],
    );
  }

  String get warningThesefeature {
    return Intl.message(
      'Warning: These features are intended for advanced users only.  Please read all instructions.',
      name: 'warningThesefeature',
      desc: '',
      args: [],
    );
  }

  String get exportHopsConfiguration {
    return Intl.message(
      'Export Hops Configuration',
      name: 'exportHopsConfiguration',
      desc: '',
      args: [],
    );
  }

  String get export {
    return Intl.message(
      'Export',
      name: 'export',
      desc: '',
      args: [],
    );
  }

  String get warningExportedConfiguration {
    return Intl.message(
      'Warning: Exported configuration includes the signer private key secrets for the exported hops.  Revealing private keys exposes you to loss of all funds in the associated Orchid accounts.',
      name: 'warningExportedConfiguration',
      desc: '',
      args: [],
    );
  }

  String get importHopsConfiguration {
    return Intl.message(
      'Import Hops Configuration',
      name: 'importHopsConfiguration',
      desc: '',
      args: [],
    );
  }

  String get import {
    return Intl.message(
      'Import',
      name: 'import',
      desc: '',
      args: [],
    );
  }

  String get warningImportedConfiguration {
    return Intl.message(
      'Warning: Imported configuration will replace any existing hops that you have created in the app.  Signer keys previously generated or imported on this device will be retained and remain accessible for creating new hops, however all other configuration including OpenVPN hop configuration will be lost.',
      name: 'warningImportedConfiguration',
      desc: '',
      args: [],
    );
  }

  String get configuration {
    return Intl.message(
      'Configuration',
      name: 'configuration',
      desc: '',
      args: [],
    );
  }

  String get saveButtonTitle {
    return Intl.message(
      'SAVE',
      name: 'saveButtonTitle',
      desc: '',
      args: [],
    );
  }

  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  String get trafficListView {
    return Intl.message(
      'traffic list view',
      name: 'trafficListView',
      desc: '',
      args: [],
    );
  }

  String get newContent {
    return Intl.message(
      'New Content',
      name: 'newContent',
      desc: '',
      args: [],
    );
  }

  String get clear {
    return Intl.message(
      'Clear',
      name: 'clear',
      desc: '',
      args: [],
    );
  }

  String get deleteAllData {
    return Intl.message(
      'Delete all data',
      name: 'deleteAllData',
      desc: '',
      args: [],
    );
  }

  String get thisWillDeleteRecorded {
    return Intl.message(
      'This will delete all recorded traffic data within the app.',
      name: 'thisWillDeleteRecorded',
      desc: '',
      args: [],
    );
  }

  String get okButtonTitle {
    return Intl.message(
      'OK',
      name: 'okButtonTitle',
      desc: '',
      args: [],
    );
  }

  String get connectionDetail {
    return Intl.message(
      'Connection Detail',
      name: 'connectionDetail',
      desc: '',
      args: [],
    );
  }

  String get host {
    return Intl.message(
      'Host',
      name: 'host',
      desc: '',
      args: [],
    );
  }

  String get time {
    return Intl.message(
      'Time',
      name: 'time',
      desc: '',
      args: [],
    );
  }

  String get sourcePort {
    return Intl.message(
      'Source Port',
      name: 'sourcePort',
      desc: '',
      args: [],
    );
  }

  String get destination {
    return Intl.message(
      'Destination',
      name: 'destination',
      desc: '',
      args: [],
    );
  }

  String get destinationPort {
    return Intl.message(
      'Destination Port',
      name: 'destinationPort',
      desc: '',
      args: [],
    );
  }

  String get generateNewKey {
    return Intl.message(
      'Generate new key',
      name: 'generateNewKey',
      desc: '',
      args: [],
    );
  }

  String get importKey {
    return Intl.message(
      'Import key',
      name: 'importKey',
      desc: '',
      args: [],
    );
  }

  String get chooseKey {
    return Intl.message(
      'Choose key',
      name: 'chooseKey',
      desc: '',
      args: [],
    );
  }

  String get welcomeToOrchid {
    return Intl.message(
      'Welcome to Orchid',
      name: 'welcomeToOrchid',
      desc: '',
      args: [],
    );
  }

  String get thisReleaseVPNInstruction {
    return Intl.message(
      'This release is Orchid’s advanced VPN client, supporting multi-hop and local traffic analysis.',
      name: 'thisReleaseVPNInstruction',
      desc: '',
      args: [],
    );
  }

  String get toGetStartedInstruction {
    return Intl.message(
      'To get started, enable the VPN.',
      name: 'toGetStartedInstruction',
      desc: '',
      args: [],
    );
  }

  String get nothingToDisplayYet {
    return Intl.message(
      'Nothing to display yet. Traffic will appear here when there’s something to show.',
      name: 'nothingToDisplayYet',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale('zh', ''), Locale('en', ''),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    if (locale != null) {
      for (Locale supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale.languageCode) {
          return true;
        }
      }
    }
    return false;
  }
}