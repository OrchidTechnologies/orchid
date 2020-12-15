// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values

class S {
  S();
  
  static S current;
  
  static const AppLocalizationDelegate delegate =
    AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name); 
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      S.current = S();
      
      return S.current;
    });
  } 

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `New Hop`
  String get newHop {
    return Intl.message(
      'New Hop',
      name: 'newHop',
      desc: 'New network hop',
      args: [],
    );
  }

  /// `Orchid Hop`
  String get orchidHop {
    return Intl.message(
      'Orchid Hop',
      name: 'orchidHop',
      desc: 'Orchid network hop',
      args: [],
    );
  }

  /// `Orchid disabled`
  String get orchidDisabled {
    return Intl.message(
      'Orchid disabled',
      name: 'orchidDisabled',
      desc: '',
      args: [],
    );
  }

  /// `Traffic monitoring only`
  String get trafficMonitoringOnly {
    return Intl.message(
      'Traffic monitoring only',
      name: 'trafficMonitoringOnly',
      desc: '',
      args: [],
    );
  }

  /// `Orchid connecting`
  String get orchidConnecting {
    return Intl.message(
      'Orchid connecting',
      name: 'orchidConnecting',
      desc: '',
      args: [],
    );
  }

  /// `Orchid disconnecting`
  String get orchidDisconnecting {
    return Intl.message(
      'Orchid disconnecting',
      name: 'orchidDisconnecting',
      desc: '',
      args: [],
    );
  }

  /// `{num, plural, zero{No hops configured} one{One hop configured} two{Two hops configured} other{{num} hops configured}}`
  String numHopsConfigured(num num) {
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

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Turn Orchid on to activate your hops and protect your traffic`
  String get turnOnToActivate {
    return Intl.message(
      'Turn Orchid on to activate your hops and protect your traffic',
      name: 'turnOnToActivate',
      desc: '',
      args: [],
    );
  }

  /// `Create your first hop to protect your connection.`
  String get createFirstHop {
    return Intl.message(
      'Create your first hop to protect your connection.',
      name: 'createFirstHop',
      desc: '',
      args: [],
    );
  }

  /// `Orchid`
  String get orchid {
    return Intl.message(
      'Orchid',
      name: 'orchid',
      desc: '',
      args: [],
    );
  }

  /// `OpenVPN`
  String get openVPN {
    return Intl.message(
      'OpenVPN',
      name: 'openVPN',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message(
      'Status',
      name: 'status',
      desc: '',
      args: [],
    );
  }

  /// `Hops`
  String get hops {
    return Intl.message(
      'Hops',
      name: 'hops',
      desc: 'Network hops',
      args: [],
    );
  }

  /// `Traffic`
  String get traffic {
    return Intl.message(
      'Traffic',
      name: 'traffic',
      desc: 'Network traffic',
      args: [],
    );
  }

  /// `To create an Orchid hop you need an Orchid account.  Open`
  String get createInstruction1 {
    return Intl.message(
      'To create an Orchid hop you need an Orchid account.  Open',
      name: 'createInstruction1',
      desc: '',
      args: [],
    );
  }

  /// `in a Web3 browser and follow the steps.  Paste in your Ethereum address below.`
  String get createInstructions2 {
    return Intl.message(
      'in a Web3 browser and follow the steps.  Paste in your Ethereum address below.',
      name: 'createInstructions2',
      desc: '',
      args: [],
    );
  }

  /// `LEARN MORE`
  String get learnMoreButtonTitle {
    return Intl.message(
      'LEARN MORE',
      name: 'learnMoreButtonTitle',
      desc: '',
      args: [],
    );
  }

  /// `Orchid requires OXT`
  String get orchidRequiresOXT {
    return Intl.message(
      'Orchid requires OXT',
      name: 'orchidRequiresOXT',
      desc: '',
      args: [],
    );
  }

  /// `Credentials`
  String get credentials {
    return Intl.message(
      'Credentials',
      name: 'credentials',
      desc: '',
      args: [],
    );
  }

  /// `Curation`
  String get curation {
    return Intl.message(
      'Curation',
      name: 'curation',
      desc: '',
      args: [],
    );
  }

  /// `Rate Limit`
  String get rateLimit {
    return Intl.message(
      'Rate Limit',
      name: 'rateLimit',
      desc: '',
      args: [],
    );
  }

  /// `Signer Key`
  String get signerKey {
    return Intl.message(
      'Signer Key',
      name: 'signerKey',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get copy {
    return Intl.message(
      'Copy',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  /// `Paste`
  String get paste {
    return Intl.message(
      'Paste',
      name: 'paste',
      desc: '',
      args: [],
    );
  }

  /// `Ethereum Address`
  String get ethereumAddress {
    return Intl.message(
      'Ethereum Address',
      name: 'ethereumAddress',
      desc: '',
      args: [],
    );
  }

  /// `OXT`
  String get oxt {
    return Intl.message(
      'OXT',
      name: 'oxt',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get amount {
    return Intl.message(
      'Amount',
      name: 'amount',
      desc: '',
      args: [],
    );
  }

  /// `Deposit`
  String get deposit {
    return Intl.message(
      'Deposit',
      name: 'deposit',
      desc: '',
      args: [],
    );
  }

  /// `Curator`
  String get curator {
    return Intl.message(
      'Curator',
      name: 'curator',
      desc: '',
      args: [],
    );
  }

  /// `View or modify your rate limit.`
  String get viewOrModifyRateLimit {
    return Intl.message(
      'View or modify your rate limit.',
      name: 'viewOrModifyRateLimit',
      desc: '',
      args: [],
    );
  }

  /// `Share Orchid Account`
  String get shareOrchidAccount {
    return Intl.message(
      'Share Orchid Account',
      name: 'shareOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `My Orchid Account`
  String get myOrchidAccount {
    return Intl.message(
      'My Orchid Account',
      name: 'myOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `Budget`
  String get budget {
    return Intl.message(
      'Budget',
      name: 'budget',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `SETTINGS`
  String get settingsButtonTitle {
    return Intl.message(
      'SETTINGS',
      name: 'settingsButtonTitle',
      desc: '',
      args: [],
    );
  }

  /// `Confirm this action`
  String get confirmThisAction {
    return Intl.message(
      'Confirm this action',
      name: 'confirmThisAction',
      desc: '',
      args: [],
    );
  }

  /// `CANCEL`
  String get cancelButtonTitle {
    return Intl.message(
      'CANCEL',
      name: 'cancelButtonTitle',
      desc: '',
      args: [],
    );
  }

  /// `Changes will take effect when the VPN is restarted.`
  String get changesWillTakeEffectInstruction {
    return Intl.message(
      'Changes will take effect when the VPN is restarted.',
      name: 'changesWillTakeEffectInstruction',
      desc: '',
      args: [],
    );
  }

  /// `Saved`
  String get saved {
    return Intl.message(
      'Saved',
      name: 'saved',
      desc: '',
      args: [],
    );
  }

  /// `Configuration saved`
  String get configurationSaved {
    return Intl.message(
      'Configuration saved',
      name: 'configurationSaved',
      desc: '',
      args: [],
    );
  }

  /// `Whoops`
  String get whoops {
    return Intl.message(
      'Whoops',
      name: 'whoops',
      desc: '',
      args: [],
    );
  }

  /// `Configuration failed to save.  Please check syntax and try again.`
  String get configurationFailedInstruction {
    return Intl.message(
      'Configuration failed to save.  Please check syntax and try again.',
      name: 'configurationFailedInstruction',
      desc: '',
      args: [],
    );
  }

  /// `Add Hop`
  String get addHop {
    return Intl.message(
      'Add Hop',
      name: 'addHop',
      desc: '',
      args: [],
    );
  }

  /// `Select your hop`
  String get selectYourHop {
    return Intl.message(
      'Select your hop',
      name: 'selectYourHop',
      desc: '',
      args: [],
    );
  }

  /// `I have a QR code`
  String get iHaveAQRCode {
    return Intl.message(
      'I have a QR code',
      name: 'iHaveAQRCode',
      desc: '',
      args: [],
    );
  }

  /// `Purchase an Account (PAC)`
  String get purchasePAC {
    return Intl.message(
      'Purchase an Account (PAC)',
      name: 'purchasePAC',
      desc: '',
      args: [],
    );
  }

  /// `I want to try Orchid`
  String get iWantToTryOrchid {
    return Intl.message(
      'I want to try Orchid',
      name: 'iWantToTryOrchid',
      desc: '',
      args: [],
    );
  }

  /// `I have an Orchid Account`
  String get iHaveOrchidAccount {
    return Intl.message(
      'I have an Orchid Account',
      name: 'iHaveOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `I have a VPN subscription`
  String get iHaveAVPNSubscription {
    return Intl.message(
      'I have a VPN subscription',
      name: 'iHaveAVPNSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Orchid requires an Orchid account.  Scan or paste your existing account below to get started.`
  String get orchidRequiresAccountInstruction {
    return Intl.message(
      'Orchid requires an Orchid account.  Scan or paste your existing account below to get started.',
      name: 'orchidRequiresAccountInstruction',
      desc: '',
      args: [],
    );
  }

  /// `Create Orchid Account`
  String get createOrchidAccount {
    return Intl.message(
      'Create Orchid Account',
      name: 'createOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `You'll need an Ethereum Wallet in order to create an Orchid account.`
  String get youNeedEthereumWallet {
    return Intl.message(
      'You\'ll need an Ethereum Wallet in order to create an Orchid account.',
      name: 'youNeedEthereumWallet',
      desc: '',
      args: [],
    );
  }

  /// `Load`
  String get loadMsg {
    return Intl.message(
      'Load',
      name: 'loadMsg',
      desc: '',
      args: [],
    );
  }

  /// `in your wallet's browser to get started.`
  String get inYourWalletBrowserInstruction {
    return Intl.message(
      'in your wallet\'s browser to get started.',
      name: 'inYourWalletBrowserInstruction',
      desc: '',
      args: [],
    );
  }

  /// `Need more help`
  String get needMoreHelp {
    return Intl.message(
      'Need more help',
      name: 'needMoreHelp',
      desc: '',
      args: [],
    );
  }

  /// `Read the guide`
  String get readTheGuide {
    return Intl.message(
      'Read the guide',
      name: 'readTheGuide',
      desc: '',
      args: [],
    );
  }

  /// `Add Orchid Account`
  String get addOrchidAccount {
    return Intl.message(
      'Add Orchid Account',
      name: 'addOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `Add Account`
  String get addAccount {
    return Intl.message(
      'Add Account',
      name: 'addAccount',
      desc: '',
      args: [],
    );
  }

  /// `Scan`
  String get scan {
    return Intl.message(
      'Scan',
      name: 'scan',
      desc: '',
      args: [],
    );
  }

  /// `Invalid QR Code`
  String get invalidQRCode {
    return Intl.message(
      'Invalid QR Code',
      name: 'invalidQRCode',
      desc: '',
      args: [],
    );
  }

  /// `The QR code you scanned does not contain a valid account configuration.`
  String get theQRCodeYouScannedDoesNot {
    return Intl.message(
      'The QR code you scanned does not contain a valid account configuration.',
      name: 'theQRCodeYouScannedDoesNot',
      desc: '',
      args: [],
    );
  }

  /// `Invalid Code`
  String get invalidCode {
    return Intl.message(
      'Invalid Code',
      name: 'invalidCode',
      desc: '',
      args: [],
    );
  }

  /// `The code you pasted does not contain a valid account configuration.`
  String get theCodeYouPastedDoesNot {
    return Intl.message(
      'The code you pasted does not contain a valid account configuration.',
      name: 'theCodeYouPastedDoesNot',
      desc: '',
      args: [],
    );
  }

  /// `OpenVPN Hop`
  String get openVPNHop {
    return Intl.message(
      'OpenVPN Hop',
      name: 'openVPNHop',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message(
      'Username',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Config`
  String get config {
    return Intl.message(
      'Config',
      name: 'config',
      desc: '',
      args: [],
    );
  }

  /// `Paste your OVPN config file here`
  String get pasteYourOVPN {
    return Intl.message(
      'Paste your OVPN config file here',
      name: 'pasteYourOVPN',
      desc: '',
      args: [],
    );
  }

  /// `Enter your credentials`
  String get enterYourCredentials {
    return Intl.message(
      'Enter your credentials',
      name: 'enterYourCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Enter the login information for your VPN provider above. Then paste the contents of your provider’s OpenVPN config file into the field provided.`
  String get enterLoginInformationInstruction {
    return Intl.message(
      'Enter the login information for your VPN provider above. Then paste the contents of your provider’s OpenVPN config file into the field provided.',
      name: 'enterLoginInformationInstruction',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Help`
  String get help {
    return Intl.message(
      'Help',
      name: 'help',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Open Source Licenses`
  String get openSourceLicenses {
    return Intl.message(
      'Open Source Licenses',
      name: 'openSourceLicenses',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Advanced`
  String get advanced {
    return Intl.message(
      'Advanced',
      name: 'advanced',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get version {
    return Intl.message(
      'Version',
      name: 'version',
      desc: '',
      args: [],
    );
  }

  /// `No version`
  String get noVersion {
    return Intl.message(
      'No version',
      name: 'noVersion',
      desc: '',
      args: [],
    );
  }

  /// `Setup`
  String get setup {
    return Intl.message(
      'Setup',
      name: 'setup',
      desc: '',
      args: [],
    );
  }

  /// `Orchid Overview`
  String get orchidOverview {
    return Intl.message(
      'Orchid Overview',
      name: 'orchidOverview',
      desc: '',
      args: [],
    );
  }

  /// `Log`
  String get log {
    return Intl.message(
      'Log',
      name: 'log',
      desc: '',
      args: [],
    );
  }

  /// `Default Curator`
  String get defaultCurator {
    return Intl.message(
      'Default Curator',
      name: 'defaultCurator',
      desc: '',
      args: [],
    );
  }

  /// `Allow No Hop VPN`
  String get allowNoHopVPN {
    return Intl.message(
      'Allow No Hop VPN',
      name: 'allowNoHopVPN',
      desc: '',
      args: [],
    );
  }

  /// `Query Balances`
  String get queryBalances {
    return Intl.message(
      'Query Balances',
      name: 'queryBalances',
      desc: '',
      args: [],
    );
  }

  /// `Show Instructions`
  String get showInstructions {
    return Intl.message(
      'Show Instructions',
      name: 'showInstructions',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  /// `Manage Configuration`
  String get manageConfiguration {
    return Intl.message(
      'Manage Configuration',
      name: 'manageConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Show Status Page`
  String get showStatusPage {
    return Intl.message(
      'Show Status Page',
      name: 'showStatusPage',
      desc: '',
      args: [],
    );
  }

  /// `beta`
  String get beta {
    return Intl.message(
      'beta',
      name: 'beta',
      desc: '',
      args: [],
    );
  }

  /// `Warning: These features are intended for advanced users only.  Please read all instructions.`
  String get warningThesefeature {
    return Intl.message(
      'Warning: These features are intended for advanced users only.  Please read all instructions.',
      name: 'warningThesefeature',
      desc: '',
      args: [],
    );
  }

  /// `Export Hops Configuration`
  String get exportHopsConfiguration {
    return Intl.message(
      'Export Hops Configuration',
      name: 'exportHopsConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Export`
  String get export {
    return Intl.message(
      'Export',
      name: 'export',
      desc: '',
      args: [],
    );
  }

  /// `Warning: Exported configuration includes the signer private key secrets for the exported hops.  Revealing private keys exposes you to loss of all funds in the associated Orchid accounts.`
  String get warningExportedConfiguration {
    return Intl.message(
      'Warning: Exported configuration includes the signer private key secrets for the exported hops.  Revealing private keys exposes you to loss of all funds in the associated Orchid accounts.',
      name: 'warningExportedConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Import Hops Configuration`
  String get importHopsConfiguration {
    return Intl.message(
      'Import Hops Configuration',
      name: 'importHopsConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get import {
    return Intl.message(
      'Import',
      name: 'import',
      desc: '',
      args: [],
    );
  }

  /// `Warning: Imported configuration will replace any existing hops that you have created in the app.  Signer keys previously generated or imported on this device will be retained and remain accessible for creating new hops, however all other configuration including OpenVPN hop configuration will be lost.`
  String get warningImportedConfiguration {
    return Intl.message(
      'Warning: Imported configuration will replace any existing hops that you have created in the app.  Signer keys previously generated or imported on this device will be retained and remain accessible for creating new hops, however all other configuration including OpenVPN hop configuration will be lost.',
      name: 'warningImportedConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Configuration`
  String get configuration {
    return Intl.message(
      'Configuration',
      name: 'configuration',
      desc: '',
      args: [],
    );
  }

  /// `SAVE`
  String get saveButtonTitle {
    return Intl.message(
      'SAVE',
      name: 'saveButtonTitle',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `traffic list view`
  String get trafficListView {
    return Intl.message(
      'traffic list view',
      name: 'trafficListView',
      desc: '',
      args: [],
    );
  }

  /// `New Content`
  String get newContent {
    return Intl.message(
      'New Content',
      name: 'newContent',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clear {
    return Intl.message(
      'Clear',
      name: 'clear',
      desc: '',
      args: [],
    );
  }

  /// `Delete all data`
  String get deleteAllData {
    return Intl.message(
      'Delete all data',
      name: 'deleteAllData',
      desc: '',
      args: [],
    );
  }

  /// `This will delete all recorded traffic data within the app.`
  String get thisWillDeleteRecorded {
    return Intl.message(
      'This will delete all recorded traffic data within the app.',
      name: 'thisWillDeleteRecorded',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get okButtonTitle {
    return Intl.message(
      'OK',
      name: 'okButtonTitle',
      desc: '',
      args: [],
    );
  }

  /// `Connection Detail`
  String get connectionDetail {
    return Intl.message(
      'Connection Detail',
      name: 'connectionDetail',
      desc: '',
      args: [],
    );
  }

  /// `Host`
  String get host {
    return Intl.message(
      'Host',
      name: 'host',
      desc: '',
      args: [],
    );
  }

  /// `Time`
  String get time {
    return Intl.message(
      'Time',
      name: 'time',
      desc: '',
      args: [],
    );
  }

  /// `Source Port`
  String get sourcePort {
    return Intl.message(
      'Source Port',
      name: 'sourcePort',
      desc: '',
      args: [],
    );
  }

  /// `Destination`
  String get destination {
    return Intl.message(
      'Destination',
      name: 'destination',
      desc: '',
      args: [],
    );
  }

  /// `Destination Port`
  String get destinationPort {
    return Intl.message(
      'Destination Port',
      name: 'destinationPort',
      desc: '',
      args: [],
    );
  }

  /// `Generate new key`
  String get generateNewKey {
    return Intl.message(
      'Generate new key',
      name: 'generateNewKey',
      desc: '',
      args: [],
    );
  }

  /// `Import key`
  String get importKey {
    return Intl.message(
      'Import key',
      name: 'importKey',
      desc: '',
      args: [],
    );
  }

  /// `Choose key`
  String get chooseKey {
    return Intl.message(
      'Choose key',
      name: 'chooseKey',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to Orchid`
  String get welcomeToOrchid {
    return Intl.message(
      'Welcome to Orchid',
      name: 'welcomeToOrchid',
      desc: '',
      args: [],
    );
  }

  /// `This release is Orchid’s advanced VPN client, supporting multi-hop and local traffic analysis.`
  String get thisReleaseVPNInstruction {
    return Intl.message(
      'This release is Orchid’s advanced VPN client, supporting multi-hop and local traffic analysis.',
      name: 'thisReleaseVPNInstruction',
      desc: '',
      args: [],
    );
  }

  /// `To get started, enable the VPN.`
  String get toGetStartedInstruction {
    return Intl.message(
      'To get started, enable the VPN.',
      name: 'toGetStartedInstruction',
      desc: '',
      args: [],
    );
  }

  /// `Nothing to display yet. Traffic will appear here when there’s something to show.`
  String get nothingToDisplayYet {
    return Intl.message(
      'Nothing to display yet. Traffic will appear here when there’s something to show.',
      name: 'nothingToDisplayYet',
      desc: '',
      args: [],
    );
  }

  /// `Disconnecting...`
  String get disconnecting {
    return Intl.message(
      'Disconnecting...',
      name: 'disconnecting',
      desc: '',
      args: [],
    );
  }

  /// `Connecting...`
  String get connecting {
    return Intl.message(
      'Connecting...',
      name: 'connecting',
      desc: '',
      args: [],
    );
  }

  /// `Push to connect.`
  String get pushToConnect {
    return Intl.message(
      'Push to connect.',
      name: 'pushToConnect',
      desc: '',
      args: [],
    );
  }

  /// `Orchid is running!`
  String get orchidIsRunning {
    return Intl.message(
      'Orchid is running!',
      name: 'orchidIsRunning',
      desc: '',
      args: [],
    );
  }

  /// `Purchase`
  String get purchase {
    return Intl.message(
      'Purchase',
      name: 'purchase',
      desc: '',
      args: [],
    );
  }

  /// `PAC Purchase Waiting`
  String get pacPurchaseWaiting {
    return Intl.message(
      'PAC Purchase Waiting',
      name: 'pacPurchaseWaiting',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message(
      'Retry',
      name: 'retry',
      desc: '',
      args: [],
    );
  }

  /// `Get help resolving this issue.`
  String get getHelpResolvingIssue {
    return Intl.message(
      'Get help resolving this issue.',
      name: 'getHelpResolvingIssue',
      desc: '',
      args: [],
    );
  }

  /// `Copy Debug Info`
  String get copyDebugInfo {
    return Intl.message(
      'Copy Debug Info',
      name: 'copyDebugInfo',
      desc: '',
      args: [],
    );
  }

  /// `Contact Orchid`
  String get contactOrchid {
    return Intl.message(
      'Contact Orchid',
      name: 'contactOrchid',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message(
      'Remove',
      name: 'remove',
      desc: '',
      args: [],
    );
  }

  /// `Delete Transaction`
  String get deleteTransaction {
    return Intl.message(
      'Delete Transaction',
      name: 'deleteTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Clear this in-progress transaction. This will not refund your in-app purchase.  You must contact Orchid to resolve the issue.`
  String get clearThisInProgressTransactionExplain {
    return Intl.message(
      'Clear this in-progress transaction. This will not refund your in-app purchase.  You must contact Orchid to resolve the issue.',
      name: 'clearThisInProgressTransactionExplain',
      desc: '',
      args: [],
    );
  }

  /// `Choose your purchase`
  String get chooseYourPurchase {
    return Intl.message(
      'Choose your purchase',
      name: 'chooseYourPurchase',
      desc: '',
      args: [],
    );
  }

  /// `Based on your bandwidth usage`
  String get basedOnYourBandwidth {
    return Intl.message(
      'Based on your bandwidth usage',
      name: 'basedOnYourBandwidth',
      desc: '',
      args: [],
    );
  }

  /// `Preparing Purchase`
  String get preparingPurchase {
    return Intl.message(
      'Preparing Purchase',
      name: 'preparingPurchase',
      desc: '',
      args: [],
    );
  }

  /// `Fetching Purchased PAC`
  String get fetchingPurchasedPAC {
    return Intl.message(
      'Fetching Purchased PAC',
      name: 'fetchingPurchasedPAC',
      desc: '',
      args: [],
    );
  }

  /// `Retrying Purchased PAC`
  String get retryingPurchasedPAC {
    return Intl.message(
      'Retrying Purchased PAC',
      name: 'retryingPurchasedPAC',
      desc: '',
      args: [],
    );
  }

  /// `Retry Purchased PAC`
  String get retryPurchasedPAC {
    return Intl.message(
      'Retry Purchased PAC',
      name: 'retryPurchasedPAC',
      desc: '',
      args: [],
    );
  }

  /// `Set up Account`
  String get setUpAccount {
    return Intl.message(
      'Set up Account',
      name: 'setUpAccount',
      desc: '',
      args: [],
    );
  }

  /// `Purchase Error`
  String get purchaseError {
    return Intl.message(
      'Purchase Error',
      name: 'purchaseError',
      desc: '',
      args: [],
    );
  }

  /// `There was an error in purchasing.  Please contact Orchid Support.`
  String get thereWasAnErrorInPurchasingContact {
    return Intl.message(
      'There was an error in purchasing.  Please contact Orchid Support.',
      name: 'thereWasAnErrorInPurchasingContact',
      desc: '',
      args: [],
    );
  }

  /// `Orchid is unique as it supports multiple VPN connections at once. Each VPN connection is a "hop".\n\nEach hop needs an active account, choose an option below.`
  String get orchidIsUniqueAsItSupportsMultipleVPN {
    return Intl.message(
      'Orchid is unique as it supports multiple VPN connections at once. Each VPN connection is a "hop".\n\nEach hop needs an active account, choose an option below.',
      name: 'orchidIsUniqueAsItSupportsMultipleVPN',
      desc: '',
      args: [],
    );
  }

  /// `Buy VPN credits`
  String get buyVpnCredits {
    return Intl.message(
      'Buy VPN credits',
      name: 'buyVpnCredits',
      desc: '',
      args: [],
    );
  }

  /// `Import an Orchid account`
  String get importAnOrchidAccount {
    return Intl.message(
      'Import an Orchid account',
      name: 'importAnOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `Create a custom account`
  String get createACustomAccount {
    return Intl.message(
      'Create a custom account',
      name: 'createACustomAccount',
      desc: '',
      args: [],
    );
  }

  /// `Enter OVPN credentials`
  String get enterOvpnCredentials {
    return Intl.message(
      'Enter OVPN credentials',
      name: 'enterOvpnCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Need an Account?`
  String get needAnAccount {
    return Intl.message(
      'Need an Account?',
      name: 'needAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `Buy prepaid credits to get started. There’s no monthly fee and you only pay for what you use.`
  String get buyPrepaidCreditsToGetStartedTheresNoMonthlyFee {
    return Intl.message(
      'Buy prepaid credits to get started. There’s no monthly fee and you only pay for what you use.',
      name: 'buyPrepaidCreditsToGetStartedTheresNoMonthlyFee',
      desc: '',
      args: [],
    );
  }

  /// `Buy Credits`
  String get buyCredits {
    return Intl.message(
      'Buy Credits',
      name: 'buyCredits',
      desc: '',
      args: [],
    );
  }

  /// `Have an Orchid account or VPN subscription?`
  String get haveAnOrchidAccountOrVpnSubscription {
    return Intl.message(
      'Have an Orchid account or VPN subscription?',
      name: 'haveAnOrchidAccountOrVpnSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Scan your existing account, create a custom account or enter OVPN credentials.`
  String get scanYourExistingAccountCreateACustomAccountOrEnter {
    return Intl.message(
      'Scan your existing account, create a custom account or enter OVPN credentials.',
      name: 'scanYourExistingAccountCreateACustomAccountOrEnter',
      desc: '',
      args: [],
    );
  }

  /// `See the options`
  String get seeTheOptions {
    return Intl.message(
      'See the options',
      name: 'seeTheOptions',
      desc: '',
      args: [],
    );
  }

  /// `Scan or Paste Account`
  String get scanOrPasteAccount {
    return Intl.message(
      'Scan or Paste Account',
      name: 'scanOrPasteAccount',
      desc: '',
      args: [],
    );
  }

  /// `Choose your amount`
  String get chooseYourAmount {
    return Intl.message(
      'Choose your amount',
      name: 'chooseYourAmount',
      desc: '',
      args: [],
    );
  }

  /// `Pay only for what you use with VPN credits, only spent while the VPN is active. No expiration period, monthly fees or charges.`
  String get payOnlyForWhatYouUseWithVpnCreditsOnly {
    return Intl.message(
      'Pay only for what you use with VPN credits, only spent while the VPN is active. No expiration period, monthly fees or charges.',
      name: 'payOnlyForWhatYouUseWithVpnCreditsOnly',
      desc: '',
      args: [],
    );
  }

  /// `Approximately`
  String get approximately {
    return Intl.message(
      'Approximately',
      name: 'approximately',
      desc: '',
      args: [],
    );
  }

  /// `GB`
  String get gb {
    return Intl.message(
      'GB',
      name: 'gb',
      desc: 'Gigabytes',
      args: [],
    );
  }

  /// `of traffic`
  String get ofTraffic {
    return Intl.message(
      'of traffic',
      name: 'ofTraffic',
      desc: 'GB of traffic',
      args: [],
    );
  }

  /// `Only for the Orchid App`
  String get onlyForTheOrchidApp {
    return Intl.message(
      'Only for the Orchid App',
      name: 'onlyForTheOrchidApp',
      desc: '',
      args: [],
    );
  }

  /// `Orchid tokens in the form of access credits are unable to be used or transferred outside of the Orchid App.`
  String get orchidTokensInTheFormOfAccessCreditsAreUnable {
    return Intl.message(
      'Orchid tokens in the form of access credits are unable to be used or transferred outside of the Orchid App.',
      name: 'orchidTokensInTheFormOfAccessCreditsAreUnable',
      desc: '',
      args: [],
    );
  }

  /// `Bandwidth value will vary`
  String get bandwidthValueWillVary {
    return Intl.message(
      'Bandwidth value will vary',
      name: 'bandwidthValueWillVary',
      desc: '',
      args: [],
    );
  }

  /// `Bandwidth is purchased in a VPN marketplace so price will fluctuate based on market dynamics.`
  String get bandwidthIsPurchasedInAVpnMarketplaceSoPriceWill {
    return Intl.message(
      'Bandwidth is purchased in a VPN marketplace so price will fluctuate based on market dynamics.',
      name: 'bandwidthIsPurchasedInAVpnMarketplaceSoPriceWill',
      desc: '',
      args: [],
    );
  }

  /// `Scan or paste your existing account below to add it as a hop.`
  String get scanOrPasteYourExistingAccountBelowToAddIt {
    return Intl.message(
      'Scan or paste your existing account below to add it as a hop.',
      name: 'scanOrPasteYourExistingAccountBelowToAddIt',
      desc: '',
      args: [],
    );
  }

  /// `Link Orchid Account`
  String get linkAnOrchidAccount {
    return Intl.message(
      'Link Orchid Account',
      name: 'linkAnOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `Enter OVPN Profile`
  String get enterOvpnProfile {
    return Intl.message(
      'Enter OVPN Profile',
      name: 'enterOvpnProfile',
      desc: '',
      args: [],
    );
  }

  /// `Buy Orchid Account`
  String get buyOrchidAccount {
    return Intl.message(
      'Buy Orchid Account',
      name: 'buyOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `Link your existing Orchid account or enter an OVPN profile.`
  String get linkYourExistingOrchidAccountOrEnterAnOvpnProfile {
    return Intl.message(
      'Link your existing Orchid account or enter an OVPN profile.',
      name: 'linkYourExistingOrchidAccountOrEnterAnOvpnProfile',
      desc: '',
      args: [],
    );
  }

  /// `We are sorry but this purchase would exceed the daily purchase limit for access credits.  Please try again later.`
  String get weAreSorryButThisPurchaseWouldExceedTheDaily {
    return Intl.message(
      'We are sorry but this purchase would exceed the daily purchase limit for access credits.  Please try again later.',
      name: 'weAreSorryButThisPurchaseWouldExceedTheDaily',
      desc: '',
      args: [],
    );
  }

  /// `Paste Account`
  String get pasteAccount {
    return Intl.message(
      'Paste Account',
      name: 'pasteAccount',
      desc: '',
      args: [],
    );
  }

  /// `Paste your existing account below to add it as a hop.`
  String get pasteYourExistingAccountBelowToAddItAsA {
    return Intl.message(
      'Paste your existing account below to add it as a hop.',
      name: 'pasteYourExistingAccountBelowToAddItAsA',
      desc: '',
      args: [],
    );
  }

  /// `Manage Profile`
  String get manageProfile {
    return Intl.message(
      'Manage Profile',
      name: 'manageProfile',
      desc: '',
      args: [],
    );
  }

  /// `Market Stats`
  String get marketStats {
    return Intl.message(
      'Market Stats',
      name: 'marketStats',
      desc: '',
      args: [],
    );
  }

  /// `Balance too low`
  String get balanceTooLow {
    return Intl.message(
      'Balance too low',
      name: 'balanceTooLow',
      desc: '',
      args: [],
    );
  }

  /// `Deposit size too small`
  String get depositSizeTooSmall {
    return Intl.message(
      'Deposit size too small',
      name: 'depositSizeTooSmall',
      desc: '',
      args: [],
    );
  }

  /// `Your max ticket value is currently limited by your balance of`
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance {
    return Intl.message(
      'Your max ticket value is currently limited by your balance of',
      name: 'yourMaxTicketValueIsCurrentlyLimitedByYourBalance',
      desc: '',
      args: [],
    );
  }

  /// `Your max ticket value is currently limited by your deposit of`
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit {
    return Intl.message(
      'Your max ticket value is currently limited by your deposit of',
      name: 'yourMaxTicketValueIsCurrentlyLimitedByYourDeposit',
      desc: '',
      args: [],
    );
  }

  /// `Consider adding OXT to your account balance.`
  String get considerAddingOxtToYourAccountBalance {
    return Intl.message(
      'Consider adding OXT to your account balance.',
      name: 'considerAddingOxtToYourAccountBalance',
      desc: '',
      args: [],
    );
  }

  /// `Consider adding OXT to your deposit or moving funds from your balance to your deposit.`
  String get considerAddingOxtToYourDepositOrMovingFundsFrom {
    return Intl.message(
      'Consider adding OXT to your deposit or moving funds from your balance to your deposit.',
      name: 'considerAddingOxtToYourDepositOrMovingFundsFrom',
      desc: '',
      args: [],
    );
  }

  /// `Prices`
  String get prices {
    return Intl.message(
      'Prices',
      name: 'prices',
      desc: '',
      args: [],
    );
  }

  /// `Ticket Value`
  String get ticketValue {
    return Intl.message(
      'Ticket Value',
      name: 'ticketValue',
      desc: '',
      args: [],
    );
  }

  /// `Cost to redeem:`
  String get costToRedeem {
    return Intl.message(
      'Cost to redeem:',
      name: 'costToRedeem',
      desc: '',
      args: [],
    );
  }

  /// `View the docs for help on this issue.`
  String get viewTheDocsForHelpOnThisIssue {
    return Intl.message(
      'View the docs for help on this issue.',
      name: 'viewTheDocsForHelpOnThisIssue',
      desc: '',
      args: [],
    );
  }

  /// `More`
  String get more {
    return Intl.message(
      'More',
      name: 'more',
      desc: '',
      args: [],
    );
  }

  /// `Traffic Monitor`
  String get trafficMonitor {
    return Intl.message(
      'Traffic Monitor',
      name: 'trafficMonitor',
      desc: '',
      args: [],
    );
  }

  /// `Try out Orchid`
  String get tryOutOrchid {
    return Intl.message(
      'Try out Orchid',
      name: 'tryOutOrchid',
      desc: '',
      args: [],
    );
  }

  /// `Good for browsing and light activity`
  String get goodForBrowsingAndLightActivity {
    return Intl.message(
      'Good for browsing and light activity',
      name: 'goodForBrowsingAndLightActivity',
      desc: '',
      args: [],
    );
  }

  /// `Average`
  String get average {
    return Intl.message(
      'Average',
      name: 'average',
      desc: '',
      args: [],
    );
  }

  /// `Good for an individual`
  String get goodForAnIndividual {
    return Intl.message(
      'Good for an individual',
      name: 'goodForAnIndividual',
      desc: '',
      args: [],
    );
  }

  /// `Short to medium term usage`
  String get shortToMediumTermUsage {
    return Intl.message(
      'Short to medium term usage',
      name: 'shortToMediumTermUsage',
      desc: '',
      args: [],
    );
  }

  /// `Heavy`
  String get heavy {
    return Intl.message(
      'Heavy',
      name: 'heavy',
      desc: '',
      args: [],
    );
  }

  /// `Good for bandwidth-heavy uses & sharing`
  String get goodForBandwidthheavyUsesSharing {
    return Intl.message(
      'Good for bandwidth-heavy uses & sharing',
      name: 'goodForBandwidthheavyUsesSharing',
      desc: '',
      args: [],
    );
  }

  /// `Longer term usage`
  String get longerTermUsage {
    return Intl.message(
      'Longer term usage',
      name: 'longerTermUsage',
      desc: '',
      args: [],
    );
  }

  /// `One-time purchase`
  String get onetimePurchase {
    return Intl.message(
      'One-time purchase',
      name: 'onetimePurchase',
      desc: '',
      args: [],
    );
  }

  /// `Spent only when the VPN is active.`
  String get spentOnlyWhenTheVpnIsActive {
    return Intl.message(
      'Spent only when the VPN is active.',
      name: 'spentOnlyWhenTheVpnIsActive',
      desc: '',
      args: [],
    );
  }

  /// `No subscription, credits don’t expire.`
  String get noSubscriptionCreditsDontExpire {
    return Intl.message(
      'No subscription, credits don’t expire.',
      name: 'noSubscriptionCreditsDontExpire',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited devices and sharing.`
  String get unlimitedDevicesAndSharing {
    return Intl.message(
      'Unlimited devices and sharing.',
      name: 'unlimitedDevicesAndSharing',
      desc: '',
      args: [],
    );
  }

  /// `Bandwidth will fluctuate based on market dynamics.`
  String get bandwidthWillFluctuateBasedOnMarketDynamics {
    return Intl.message(
      'Bandwidth will fluctuate based on market dynamics.',
      name: 'bandwidthWillFluctuateBasedOnMarketDynamics',
      desc: '',
      args: [],
    );
  }

  /// `Learn more.`
  String get learnMore {
    return Intl.message(
      'Learn more.',
      name: 'learnMore',
      desc: '',
      args: [],
    );
  }

  /// `Enter WireGuard®️ Profile`
  String get enterWireguardProfile {
    return Intl.message(
      'Enter WireGuard®️ Profile',
      name: 'enterWireguardProfile',
      desc: '',
      args: [],
    );
  }

  /// `Purchase Orchid Credits to connect with Orchid.`
  String get purchaseOrchidCreditsToConnectWithOrchid {
    return Intl.message(
      'Purchase Orchid Credits to connect with Orchid.',
      name: 'purchaseOrchidCreditsToConnectWithOrchid',
      desc: '',
      args: [],
    );
  }

  /// `Create or link an Orchid account, import an OVPN profile or build a multi-hop connection to get started.`
  String get createOrLinkAnOrchidAccountImportAnOvpnProfile {
    return Intl.message(
      'Create or link an Orchid account, import an OVPN profile or build a multi-hop connection to get started.',
      name: 'createOrLinkAnOrchidAccountImportAnOvpnProfile',
      desc: '',
      args: [],
    );
  }

  /// `Buy Orchid Credits`
  String get buyOrchidCredits {
    return Intl.message(
      'Buy Orchid Credits',
      name: 'buyOrchidCredits',
      desc: '',
      args: [],
    );
  }

  /// `Have an Orchid Account or OXT?`
  String get haveAnOrchidAccountOrOxt {
    return Intl.message(
      'Have an Orchid Account or OXT?',
      name: 'haveAnOrchidAccountOrOxt',
      desc: '',
      args: [],
    );
  }

  /// `Already have an Orchid Account?`
  String get alreadyHaveAnOrchidAccount {
    return Intl.message(
      'Already have an Orchid Account?',
      name: 'alreadyHaveAnOrchidAccount',
      desc: '',
      args: [],
    );
  }

  /// `Scan or paste your existing account below.`
  String get scanOrPasteYourExistingAccountBelow {
    return Intl.message(
      'Scan or paste your existing account below.',
      name: 'scanOrPasteYourExistingAccountBelow',
      desc: '',
      args: [],
    );
  }

  /// `Custom Setup`
  String get customSetup {
    return Intl.message(
      'Custom Setup',
      name: 'customSetup',
      desc: '',
      args: [],
    );
  }

  /// `New to Orchid?`
  String get newToOrchid {
    return Intl.message(
      'New to Orchid?',
      name: 'newToOrchid',
      desc: '',
      args: [],
    );
  }

  /// `Purchase Orchid Credits, link an account or OVPN profile to get started.`
  String get purchaseOrchidCreditsLinkAnAccountOrOvpnProfileTo {
    return Intl.message(
      'Purchase Orchid Credits, link an account or OVPN profile to get started.',
      name: 'purchaseOrchidCreditsLinkAnAccountOrOvpnProfileTo',
      desc: '',
      args: [],
    );
  }

  /// `Create an Orchid account, link an existing account or import an OVPN profile.`
  String get createAnOrchidAccountLinkAnExistingAccountOrImport {
    return Intl.message(
      'Create an Orchid account, link an existing account or import an OVPN profile.',
      name: 'createAnOrchidAccountLinkAnExistingAccountOrImport',
      desc: '',
      args: [],
    );
  }

  /// `Connect`
  String get connect {
    return Intl.message(
      'Connect',
      name: 'connect',
      desc: '',
      args: [],
    );
  }

  /// `Disconnect`
  String get disconnect {
    return Intl.message(
      'Disconnect',
      name: 'disconnect',
      desc: '',
      args: [],
    );
  }

  /// `WireGuard®️ Hop`
  String get wireguardHop {
    return Intl.message(
      'WireGuard®️ Hop',
      name: 'wireguardHop',
      desc: '',
      args: [],
    );
  }

  /// `Paste your WireGuard®️ config file here`
  String get pasteYourWireguardConfigFileHere {
    return Intl.message(
      'Paste your WireGuard®️ config file here',
      name: 'pasteYourWireguardConfigFileHere',
      desc: '',
      args: [],
    );
  }

  /// `Paste the credential information for your WireGuard®️ provider into the field above.`
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe {
    return Intl.message(
      'Paste the credential information for your WireGuard®️ provider into the field above.',
      name: 'pasteTheCredentialInformationForYourWireguardProviderIntoThe',
      desc: '',
      args: [],
    );
  }

  /// `WireGuard®️`
  String get wireguard {
    return Intl.message(
      'WireGuard®️',
      name: 'wireguard',
      desc: '',
      args: [],
    );
  }

  /// `Clear all log data?`
  String get clearAllLogData {
    return Intl.message(
      'Clear all log data?',
      name: 'clearAllLogData',
      desc: '',
      args: [],
    );
  }

  /// `This debug log is non-persistent and cleared when quitting the app.`
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe {
    return Intl.message(
      'This debug log is non-persistent and cleared when quitting the app.',
      name: 'thisDebugLogIsNonpersistentAndClearedWhenQuittingThe',
      desc: '',
      args: [],
    );
  }

  /// `It may contain secret or personally identifying information.`
  String get itMayContainSecretOrPersonallyIdentifyingInformation {
    return Intl.message(
      'It may contain secret or personally identifying information.',
      name: 'itMayContainSecretOrPersonallyIdentifyingInformation',
      desc: '',
      args: [],
    );
  }

  /// `Logging enabled`
  String get loggingEnabled {
    return Intl.message(
      'Logging enabled',
      name: 'loggingEnabled',
      desc: '',
      args: [],
    );
  }

  /// `CANCEL`
  String get cancel {
    return Intl.message(
      'CANCEL',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Logging`
  String get logging {
    return Intl.message(
      'Logging',
      name: 'logging',
      desc: '',
      args: [],
    );
  }

  /// `Loading ...`
  String get loading {
    return Intl.message(
      'Loading ...',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `ETH price:`
  String get ethPrice {
    return Intl.message(
      'ETH price:',
      name: 'ethPrice',
      desc: '',
      args: [],
    );
  }

  /// `OXT price:`
  String get oxtPrice {
    return Intl.message(
      'OXT price:',
      name: 'oxtPrice',
      desc: '',
      args: [],
    );
  }

  /// `Gas price:`
  String get gasPrice {
    return Intl.message(
      'Gas price:',
      name: 'gasPrice',
      desc: '',
      args: [],
    );
  }

  /// `Max face value:`
  String get maxFaceValue {
    return Intl.message(
      'Max face value:',
      name: 'maxFaceValue',
      desc: '',
      args: [],
    );
  }

  /// `Deleted Hops`
  String get deletedHops {
    return Intl.message(
      'Deleted Hops',
      name: 'deletedHops',
      desc: '',
      args: [],
    );
  }

  /// `Recently Deleted`
  String get recentlyDeleted {
    return Intl.message(
      'Recently Deleted',
      name: 'recentlyDeleted',
      desc: '',
      args: [],
    );
  }

  /// `No recently deleted hops...`
  String get noRecentlyDeletedHops {
    return Intl.message(
      'No recently deleted hops...',
      name: 'noRecentlyDeletedHops',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Delete`
  String get confirmDelete {
    return Intl.message(
      'Confirm Delete',
      name: 'confirmDelete',
      desc: '',
      args: [],
    );
  }

  /// `Deleting this hop will permanently remove the contained account information.`
  String get deletingThisHopWillPermanentlyRemoveTheContainedAccountInformation {
    return Intl.message(
      'Deleting this hop will permanently remove the contained account information.',
      name: 'deletingThisHopWillPermanentlyRemoveTheContainedAccountInformation',
      desc: '',
      args: [],
    );
  }

  /// `Deleting this hop will remove its configured or purchased account information.`
  String get deletingThisHopWillRemoveItsConfiguredOrPurchasedAccount {
    return Intl.message(
      'Deleting this hop will remove its configured or purchased account information.',
      name: 'deletingThisHopWillRemoveItsConfiguredOrPurchasedAccount',
      desc: '',
      args: [],
    );
  }

  /// `If you plan to re-use the account later you should first save it using either the 'share hop' option or by backing up your entire circuit configuration with the Configuration Management tool in Settings.`
  String get ifYouPlanToReuseTheAccountLaterYouShould {
    return Intl.message(
      'If you plan to re-use the account later you should first save it using either the \'share hop\' option or by backing up your entire circuit configuration with the Configuration Management tool in Settings.',
      name: 'ifYouPlanToReuseTheAccountLaterYouShould',
      desc: '',
      args: [],
    );
  }

  /// `Enter OpenVPN Config`
  String get enterOpenvpnConfig {
    return Intl.message(
      'Enter OpenVPN Config',
      name: 'enterOpenvpnConfig',
      desc: '',
      args: [],
    );
  }

  /// `Enter WireGuard®️ Config`
  String get enterWireguardConfig {
    return Intl.message(
      'Enter WireGuard®️ Config',
      name: 'enterWireguardConfig',
      desc: '',
      args: [],
    );
  }

  /// `Starting...`
  String get starting {
    return Intl.message(
      'Starting...',
      name: 'starting',
      desc: '',
      args: [],
    );
  }

  /// `Orchid is starting.`
  String get orchidIsStarting {
    return Intl.message(
      'Orchid is starting.',
      name: 'orchidIsStarting',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'id'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ko'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'zh'),
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
      for (var supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale.languageCode) {
          return true;
        }
      }
    }
    return false;
  }
}