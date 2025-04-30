// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get orchidHop => 'Orchid Hop';

  @override
  String get orchidDisabled => 'Orchid disabled';

  @override
  String get trafficMonitoringOnly => 'Traffic monitoring only';

  @override
  String get orchidConnecting => 'Orchid connecting';

  @override
  String get orchidDisconnecting => 'Orchid disconnecting';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num hops configured',
      two: 'Two hops configured',
      one: 'One hop configured',
      zero: 'No hops configured',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Delete';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Hops';

  @override
  String get traffic => 'Traffic';

  @override
  String get curation => 'Curation';

  @override
  String get signerKey => 'Signer Key';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get deposit => 'Deposit';

  @override
  String get curator => 'Curator';

  @override
  String get ok => 'OK';

  @override
  String get settingsButtonTitle => 'SETTINGS';

  @override
  String get confirmThisAction => 'Confirm this action';

  @override
  String get cancelButtonTitle => 'CANCEL';

  @override
  String get changesWillTakeEffectInstruction =>
      'Changes will take effect when the VPN is restarted.';

  @override
  String get saved => 'Saved';

  @override
  String get configurationSaved => 'Configuration saved';

  @override
  String get whoops => 'Whoops';

  @override
  String get configurationFailedInstruction =>
      'Configuration failed to save.  Please check syntax and try again.';

  @override
  String get addHop => 'Add Hop';

  @override
  String get scan => 'Scan';

  @override
  String get invalidQRCode => 'Invalid QR Code';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'The QR code you scanned does not contain a valid account configuration.';

  @override
  String get invalidCode => 'Invalid Code';

  @override
  String get theCodeYouPastedDoesNot =>
      'The code you pasted does not contain a valid account configuration.';

  @override
  String get openVPNHop => 'OpenVPN Hop';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get config => 'Config';

  @override
  String get pasteYourOVPN => 'Paste your OVPN config file here';

  @override
  String get enterYourCredentials => 'Enter your credentials';

  @override
  String get enterLoginInformationInstruction =>
      'Enter the login information for your VPN provider above. Then paste the contents of your provider’s OpenVPN config file into the field provided.';

  @override
  String get save => 'Save';

  @override
  String get help => 'Help';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get settings => 'Settings';

  @override
  String get version => 'Version';

  @override
  String get noVersion => 'No version';

  @override
  String get orchidOverview => 'Orchid Overview';

  @override
  String get defaultCurator => 'Default Curator';

  @override
  String get queryBalances => 'Query Balances';

  @override
  String get reset => 'Reset';

  @override
  String get manageConfiguration => 'Manage Configuration';

  @override
  String get warningThesefeature =>
      'Warning: These features are intended for advanced users only.  Please read all instructions.';

  @override
  String get exportHopsConfiguration => 'Export Hops Configuration';

  @override
  String get export => 'Export';

  @override
  String get warningExportedConfiguration =>
      'Warning: Exported configuration includes the signer private key secrets for the exported hops.  Revealing private keys exposes you to loss of all funds in the associated Orchid accounts.';

  @override
  String get importHopsConfiguration => 'Import Hops Configuration';

  @override
  String get import => 'Import';

  @override
  String get warningImportedConfiguration =>
      'Warning: Imported configuration will replace any existing hops that you have created in the app.  Signer keys previously generated or imported on this device will be retained and remain accessible for creating new hops, however all other configuration including OpenVPN hop configuration will be lost.';

  @override
  String get configuration => 'Configuration';

  @override
  String get saveButtonTitle => 'SAVE';

  @override
  String get search => 'Search';

  @override
  String get newContent => 'New Content';

  @override
  String get clear => 'Clear';

  @override
  String get connectionDetail => 'Connection Detail';

  @override
  String get host => 'Host';

  @override
  String get time => 'Time';

  @override
  String get sourcePort => 'Source Port';

  @override
  String get destination => 'Destination';

  @override
  String get destinationPort => 'Destination Port';

  @override
  String get generateNewKey => 'Generate new key';

  @override
  String get importKey => 'Import key';

  @override
  String get nothingToDisplayYet =>
      'Nothing to display yet. Traffic will appear here when there’s something to show.';

  @override
  String get disconnecting => 'Disconnecting...';

  @override
  String get connecting => 'Connecting...';

  @override
  String get pushToConnect => 'Push to connect.';

  @override
  String get orchidIsRunning => 'Orchid is running!';

  @override
  String get pacPurchaseWaiting => 'Purchase Waiting';

  @override
  String get retry => 'Retry';

  @override
  String get getHelpResolvingIssue => 'Get help resolving this issue.';

  @override
  String get copyDebugInfo => 'Copy Debug Info';

  @override
  String get contactOrchid => 'Contact Orchid';

  @override
  String get remove => 'Remove';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Clear this in-progress transaction. This will not refund your in-app purchase.  You must contact Orchid to resolve the issue.';

  @override
  String get preparingPurchase => 'Preparing Purchase';

  @override
  String get retryingPurchasedPAC => 'Retrying Purchase';

  @override
  String get retryPurchasedPAC => 'Retry Purchase';

  @override
  String get purchaseError => 'Purchase Error';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'There was an error in purchasing.  Please contact Orchid Support.';

  @override
  String get importAnOrchidAccount => 'Import an Orchid Account';

  @override
  String get buyCredits => 'Buy Credits';

  @override
  String get linkAnOrchidAccount => 'Link Orchid Account';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'We are sorry but this purchase would exceed the daily purchase limit for access credits.  Please try again later.';

  @override
  String get marketStats => 'Market Stats';

  @override
  String get balanceTooLow => 'Balance too low';

  @override
  String get depositSizeTooSmall => 'Deposit size too small';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'Your max ticket value is currently limited by your balance of';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'Your max ticket value is currently limited by your deposit of';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Consider adding OXT to your account balance.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Consider adding OXT to your deposit or moving funds from your balance to your deposit.';

  @override
  String get prices => 'Prices';

  @override
  String get ticketValue => 'Ticket Value';

  @override
  String get costToRedeem => 'Cost to redeem:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'View the docs for help on this issue.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Good for browsing and light activity';

  @override
  String get learnMore => 'Learn more.';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get wireguardHop => 'WireGuard®️ Hop';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Paste your WireGuard®️ config file here';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Paste the credential information for your WireGuard®️ provider into the field above.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => 'Clear all log data?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'This debug log is non-persistent and cleared when quitting the app.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'It may contain secret or personally identifying information.';

  @override
  String get loggingEnabled => 'Logging enabled';

  @override
  String get cancel => 'CANCEL';

  @override
  String get logging => 'Logging';

  @override
  String get loading => 'Loading ...';

  @override
  String get ethPrice => 'ETH price:';

  @override
  String get oxtPrice => 'OXT price:';

  @override
  String get gasPrice => 'Gas price:';

  @override
  String get maxFaceValue => 'Max face value:';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get enterOpenvpnConfig => 'Enter OpenVPN Config';

  @override
  String get enterWireguardConfig => 'Enter WireGuard®️ Config';

  @override
  String get starting => 'Starting...';

  @override
  String get legal => 'Legal';

  @override
  String get whatsNewInOrchid => 'What’s new in Orchid';

  @override
  String get orchidIsOnXdai => 'Orchid is on xDai!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'You can now purchase Orchid credits on xDai! Start using the VPN for as little as \$1.';

  @override
  String get xdaiAccountsForPastPurchases => 'xDai accounts for past purchases';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'For any in-app purchase made before today, xDai funds have been added to the same account key. Have the bandwidth on us!';

  @override
  String get newInterface => 'New interface';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'Accounts are now organized under the Orchid Address they are associated with.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'See your active account balance and bandwidth cost on the home screen.';

  @override
  String get seeOrchidcomForHelp => 'See orchid.com for help.';

  @override
  String get payPerUseVpnService => 'Pay Per Use VPN Service';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Not a subscription, credits don\'t expire';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Share account with unlimited devices';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'The Orchid Store is temporarily unavailable.  Please check back in a few minutes.';

  @override
  String get talkingToPacServer => 'Talking to Orchid Account Server';

  @override
  String get advancedConfiguration => 'Advanced Configuration';

  @override
  String get newWord => 'New';

  @override
  String get copied => 'Copied';

  @override
  String get efficiency => 'Efficiency';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Min Tickets available: $tickets';
  }

  @override
  String get transactionSentToBlockchain => 'Transaction Sent To Blockchain';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Your purchase is complete and is now being processed by the xDai blockchain which can take up to a minute, sometimes longer. Pull down to refresh and your account with an updated balance will appear below.';

  @override
  String get copyReceipt => 'Copy Receipt';

  @override
  String get manageAccounts => 'Manage Accounts';

  @override
  String get configurationManagement => 'Configuration Management';

  @override
  String get exportThisOrchidKey => 'Export this Orchid Key';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'A QR code and text for all the Orchid accounts associated with this key is below.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Import this key on another device to share all the Orchid accounts associated with this Orchid identity.';

  @override
  String get orchidAccountInUse => 'Orchid Account in use';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'This Orchid Account is in use and cannot be deleted.';

  @override
  String get pullToRefresh => 'Pull to refresh.';

  @override
  String get balance => 'Balance';

  @override
  String get active => 'Active';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Paste an Orchid key from the clipboard to import all the Orchid accounts associated with that key.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Scan or paste an Orchid key from the clipboard to import all the Orchid accounts associated with that key.';

  @override
  String get account => 'Account';

  @override
  String get transactions => 'Transactions';

  @override
  String get weRecommendBackingItUp =>
      'We recommend <link>backing it up</link>.';

  @override
  String get copiedOrchidIdentity => 'Copied Orchid Identity';

  @override
  String get thisIsNotAWalletAddress => 'This is not a wallet address.';

  @override
  String get doNotSendTokensToThisAddress =>
      'Do not send tokens to this address.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Your Orchid Identity uniquely identifies you on the network.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'Learn more about your <link>Orchid Identity</link>.';

  @override
  String get analyzingYourConnections => 'Analyzing Your Connections';

  @override
  String get analyzeYourConnections => 'Analyze Your Connections';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'Network analysis uses your device\'s VPN facility to capture packets and analyze your traffic.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'Network analysis requires VPN permissions but does not by itself protect your data or hide your IP address.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'To get the benefits of network privacy you must configure and activate a VPN connection from the home screen.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Turning on this feature will increase the battery usage of the Orchid App.';

  @override
  String get useAnOrchidAccount => 'Use an Orchid Account';

  @override
  String get pasteAddress => 'Paste Address';

  @override
  String get chooseAddress => 'Choose Address';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Choose an Orchid Account to use with this hop.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'If you don\'t see your account below you can use the account manager to import, purchase, or create a new one.';

  @override
  String get selectAnOrchidAccount => 'Select an Orchid Account';

  @override
  String get takeMeToTheAccountManager => 'Take me to the Account Manager';

  @override
  String get funderAccount => 'Funder Account';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid running and analyzing';

  @override
  String get startingVpn => '(Starting VPN)';

  @override
  String get disconnectingVpn => '(Disconnecting VPN)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid analyzing traffic';

  @override
  String get vpnConnectedButNotRouting => '(VPN connected but not routing)';

  @override
  String get restarting => 'Restarting';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'Changing monitoring status requires restarting the VPN, which may briefly interrupt privacy protection.';

  @override
  String get confirmRestart => 'Confirm Restart';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'Average price is $price USD per GB';
  }

  @override
  String get myOrchidConfig => 'My Orchid Config';

  @override
  String get noAccountSelected => 'No account selected';

  @override
  String get inactive => 'Inactive';

  @override
  String get tickets => 'Tickets';

  @override
  String get accounts => 'Accounts';

  @override
  String get orchidIdentity => 'Orchid Identity';

  @override
  String get addFunds => 'ADD FUNDS';

  @override
  String get addFunds2 => 'Add Funds';

  @override
  String get gb => 'GB';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'Hop';

  @override
  String get circuit => 'Circuit';

  @override
  String get clearAllAnalysisData => 'Clear all analysis data?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'This action will clear all previously analyzed traffic connection data.';

  @override
  String get clearAll => 'CLEAR ALL';

  @override
  String get stopAnalysis => 'STOP ANALYSIS';

  @override
  String get startAnalysis => 'START ANALYSIS';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Orchid accounts include 24/7 customer support, unlimited devices and are backed by the <link2>xDai cryptocurrency</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Purchased accounts connect exclusively to our <link1>preferred providers</link1>.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Refund policy covered by app stores.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid is unable to display in-app purchases at this time.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Please confirm that this device supports and is configured for in-app purchases.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Please confirm that this device supports and is configured for in-app purchases or use our decentralized <link>account management</link> system.';

  @override
  String get buy => 'BUY';

  @override
  String get gbApproximately12 => '12GB (approximately)';

  @override
  String get gbApproximately60 => '60GB (approximately)';

  @override
  String get gbApproximately240 => '240GB (approximately)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'Ideal size for medium-term, individual usage that includes browsing and light streaming.';

  @override
  String get mostPopular => 'Most Popular!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Bandwidth-heavy, long-term usage or shared accounts.';

  @override
  String get total => 'Total';

  @override
  String get pausingAllTraffic => 'Pausing all traffic...';

  @override
  String get queryingEthereumForARandom =>
      'Querying Ethereum for a random provider...';

  @override
  String get quickFundAnAccount => 'Quick fund an account!';

  @override
  String get accountFound => 'Account Found';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'We found an account associated with your identities and created a single hop Orchid circuit for it.  You are now ready to use the VPN.';

  @override
  String get welcomeToOrchid => 'Welcome to Orchid!';

  @override
  String get fundYourAccount => 'Fund Your Account';

  @override
  String get processing => 'Processing...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Subscription-free, pay as you go, decentralized, open source VPN service.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'GET STARTED FOR $smallAmount';
  }

  @override
  String get importAccount => 'Import Account';

  @override
  String get illDoThisLater => 'I\'ll do this later';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Connect automatically to one of the network’s <link1>preferred providers</link1> by purchasing VPN credits to fund your shareable, refillable Orchid account.';

  @override
  String get confirmPurchase => 'CONFIRM PURCHASE';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Orchid accounts use VPN credits backed by the <link>xDAI cryptocurrency</link>, include 24/7 customer support, unlimited device sharing and are covered by app store refund policies.';

  @override
  String get yourPurchaseIsInProgress => 'Your purchase is in progress.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'This purchase is taking longer than expected to process and may have encountered an error.';

  @override
  String get thisMayTakeAMinute => 'This may take a minute...';

  @override
  String get vpnCredits => 'VPN Credits';

  @override
  String get blockchainFee => 'Blockchain fee';

  @override
  String get promotion => 'Promotion';

  @override
  String get showInAccountManager => 'Show in Account Manager';

  @override
  String get deleteThisOrchidIdentity => 'Delete this Orchid Identity';

  @override
  String get chooseIdentity => 'Choose Identity';

  @override
  String get updatingAccounts => 'Updating Accounts';

  @override
  String get trafficAnalysis => 'Traffic Analysis';

  @override
  String get accountManager => 'Account Manager';

  @override
  String get circuitBuilder => 'Circuit Builder';

  @override
  String get exitHop => 'Exit Hop';

  @override
  String get entryHop => 'Entry Hop';

  @override
  String get addNewHop => 'ADD NEW HOP';

  @override
  String get newCircuitBuilder => 'New circuit builder!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'You can now pay for a multi-hop Orchid circuit with xDAI. The multihop interface now supports xDAI and OXT Orchid accounts and still supports OpenVPN and WireGuard configs that can be strung together into an onion route.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Manage your connection from the circuit builder instead of the account manager. All connections now use a circuit with zero or more hops. Any existing configuration has been migrated to the circuit builder.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Quick start for $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'We added a method to purchase an Orchid account and create a single hop circuit from the homescreen to shortcut the onboarding process.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid is unique as a multi-hop or onion routing client supporting multiple VPN protocols. You can set up your connection by chaining together hops from the supported protocols below.\n\nOne hop is like a regular VPN. Three hops (for advanced users) is the classic onion routing choice.  Zero hops allows traffic analysis without any VPN tunnel.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'Deleting OpenVPN and Wireguard hops will lose any associated credentials and connection configuration. Be sure to back up any information before continuing.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'This cannot be undone.  To save this identity hit cancel and use the Export option';

  @override
  String get unlockTime => 'Unlock Time';

  @override
  String get chooseChain => 'Choose Chain';

  @override
  String get unlocking => 'Unlocking';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get orchidTransaction => 'Orchid Transaction';

  @override
  String get confirmations => 'Confirmations';

  @override
  String get pending => 'Pending...';

  @override
  String get txHash => 'Tx Hash:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'All of your funds are available for withdrawal.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return '$maxWithdraw of your $totalFunds combined funds are currently available for withdrawal.';
  }

  @override
  String get alsoUnlockRemainingDeposit => 'Also unlock remaining deposit';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'If you specify less than the full amount funds will be drawn from your balance first.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'For additional options see the ADVANCED panel.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'If you select the unlock deposit option this transaction will immediately withdraw the specified amount from your balance and also begin the unlock process for your remaining deposit.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Deposit funds are available for withdrawal 24 hours after unlocking.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Withdraw funds from your Orchid Account to your current wallet.';

  @override
  String get withdrawAndUnlockFunds => 'WITHDRAW AND UNLOCK FUNDS';

  @override
  String get withdrawFunds => 'WITHDRAW FUNDS';

  @override
  String get withdrawFunds2 => 'Withdraw Funds';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get submitTransaction => 'SUBMIT TRANSACTION';

  @override
  String get move => 'Move';

  @override
  String get now => 'Now';

  @override
  String get amount => 'Amount';

  @override
  String get available => 'Available';

  @override
  String get select => 'Select';

  @override
  String get add => 'ADD';

  @override
  String get balanceToDeposit => 'BALANCE TO DEPOSIT';

  @override
  String get depositToBalance => 'DEPOSIT TO BALANCE';

  @override
  String get setWarnedAmount => 'Set Warned Amount';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Add funds to your Orchid Account balance and/or deposit.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'For guidance on sizing your account see <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Current $tokenType pre-authorization: $amount';
  }

  @override
  String get noWallet => 'No Wallet';

  @override
  String get noWalletOrBrowserNotSupported =>
      'No Wallet or Browser not supported.';

  @override
  String get error => 'Error';

  @override
  String get failedToConnectToWalletconnect =>
      'Failed to connect to WalletConnect.';

  @override
  String get unknownChain => 'Unknown Chain';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'The Orchid Account Manager doesn\'t support this chain yet.';

  @override
  String get orchidIsntOnThisChain => 'Orchid isn\'t on this chain.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'The Orchid contract hasn\'t been deployed on this chain yet.';

  @override
  String get moveFunds => 'MOVE FUNDS';

  @override
  String get moveFunds2 => 'Move Funds';

  @override
  String get lockUnlock => 'LOCK / UNLOCK';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'Your deposit of $amount is unlocked.';
  }

  @override
  String get locked => 'locked';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'Your deposit of $amount is $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'The funds will be available for withdrawal in $time.';
  }

  @override
  String get lockDeposit => 'LOCK DEPOSIT';

  @override
  String get unlockDeposit => 'UNLOCK DEPOSIT';

  @override
  String get advanced => 'ADVANCED';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Learn more about Orchid Accounts</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Estimated cost to create an Orchid Account with an efficiency of $efficiency and $num tickets of value.';
  }

  @override
  String get chain => 'Chain';

  @override
  String get token => 'Token';

  @override
  String get minDeposit => 'Min Deposit';

  @override
  String get minBalance => 'Min Balance';

  @override
  String get fundFee => 'Fund Fee';

  @override
  String get withdrawFee => 'Withdraw Fee';

  @override
  String get tokenValues => 'TOKEN VALUES';

  @override
  String get usdPrices => 'USD PRICES';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'Setting a warned deposit amount begins the 24 hour waiting period required to withdraw deposit funds.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'During this period the funds are not available as a valid deposit on the Orchid network.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Funds may be re-locked at any time by reducing the warned amount.';

  @override
  String get warn => 'Warn';

  @override
  String get totalWarnedAmount => 'Total Warned Amount';

  @override
  String get newIdentity => 'New Identity';

  @override
  String get importIdentity => 'Import Identity';

  @override
  String get exportIdentity => 'Export Identity';

  @override
  String get deleteIdentity => 'Delete Identity';

  @override
  String get importOrchidIdentity => 'Import Orchid Identity';

  @override
  String get funderAddress => 'Funder Address';

  @override
  String get contract => 'Contract';

  @override
  String get txFee => 'Tx Fee';

  @override
  String get show => 'Show';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Errors';

  @override
  String get lastHour => 'Last Hour';

  @override
  String get chainSettings => 'Chain Settings';

  @override
  String get price => 'Price';

  @override
  String get failed => 'Failed';

  @override
  String get fetchGasPrice => 'Fetch gas price';

  @override
  String get fetchLotteryPot => 'Fetch lottery pot';

  @override
  String get lines => 'lines';

  @override
  String get filtered => 'filtered';

  @override
  String get backUpYourIdentity => 'Back up your Identity';

  @override
  String get accountSetUp => 'Account set up';

  @override
  String get setUpAccount => 'SET UP ACCOUNT';

  @override
  String get generateIdentity => 'GENERATE IDENTITY';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Enter an existing <account_link>Orchid Identity</account_link>';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Paste the web3 wallet address that you will use to fund your account below.';

  @override
  String get funderWalletAddress => 'Funder wallet address';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Your Orchid Identity public address';

  @override
  String get continueButton => 'CONTINUE';

  @override
  String get yesIHaveSavedACopyOf =>
      'Yes, I have saved a copy of my private key somewhere secure.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Back up your Orchid Identity <bold>private key</bold>. You will need this key to share, import or restore this identity and all associated accounts.';

  @override
  String get locked1 => 'Locked';

  @override
  String get unlockDeposit1 => 'Unlock deposit';

  @override
  String get changeWarnedAmountTo => 'Change Warned Amount To';

  @override
  String get setWarnedAmountTo => 'Set Warned Amount To';

  @override
  String get currentWarnedAmount => 'Current Warned Amount';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'All warned funds will be locked until';

  @override
  String get balanceToDeposit1 => 'Balance to Deposit';

  @override
  String get depositToBalance1 => 'Deposit to Balance';

  @override
  String get advanced1 => 'Advanced';

  @override
  String get add1 => 'Add';

  @override
  String get lockUnlock1 => 'Lock / Unlock';

  @override
  String get viewLogs => 'View Logs';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get identiconStyle => 'Identicon Style';

  @override
  String get blockies => 'Blockies';

  @override
  String get jazzicon => 'Jazzicon';

  @override
  String get contractVersion => 'Contract Version';

  @override
  String get version0 => 'Version 0';

  @override
  String get version1 => 'Version 1';

  @override
  String get connectedWithMetamask => 'Connected with Metamask';

  @override
  String get blockExplorer => 'Block Explorer';

  @override
  String get tapToMinimize => 'Tap to Minimize';

  @override
  String get connectWallet => 'CONNECT WALLET';

  @override
  String get checkWallet => 'Check Wallet';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Check your Wallet app or extension for a pending request.';

  @override
  String get test => 'Test';

  @override
  String get chainName => 'Chain name';

  @override
  String get rpcUrl => 'RPC Url';

  @override
  String get tokenPrice => 'Token Price';

  @override
  String get tokenPriceUsd => 'Token Price USD';

  @override
  String get addChain => 'Add Chain';

  @override
  String get deleteChainQuestion => 'Delete Chain?';

  @override
  String get deleteUserConfiguredChain => 'Delete user-configured chain';

  @override
  String get fundContractDeployer => 'Fund Contract Deployer';

  @override
  String get deploySingletonFactory => 'Deploy Singleton Factory';

  @override
  String get deployContract => 'Deploy Contract';

  @override
  String get about => 'About';

  @override
  String get dappVersion => 'Dapp Version';

  @override
  String get viewContractOnEtherscan => 'View Contract on Etherscan';

  @override
  String get viewContractOnGithub => 'View Contract on Github';

  @override
  String get accountChanges => 'Account Changes';

  @override
  String get name => 'Name';

  @override
  String get step1 =>
      '<bold>Step 1.</bold> Connect an ERC-20 wallet with <link>enough tokens</link> in it.';

  @override
  String get step2 =>
      '<bold>Step 2.</bold> Copy the Orchid Identity from the Orchid App by going to Manage Accounts then tapping the address.';

  @override
  String get connectOrCreate => 'Connect or create Orchid Account';

  @override
  String get lockDeposit2 => 'Lock Deposit';

  @override
  String get unlockDeposit2 => 'Unlock Deposit';

  @override
  String get enterYourWeb3 => 'Enter your web3 wallet address.';

  @override
  String get purchaseComplete => 'Purchase Complete';

  @override
  String get generateNewIdentity => 'Generate a new Identity';

  @override
  String get copyIdentity => 'Copy Identity';

  @override
  String get yourPurchaseIsComplete =>
      'Your purchase is complete and is now being processed by the xDai blockchain, which could take a few minutes.  A default circuit has been generated for you using this account. You can monitor the available balance on the home screen or in the account manager.';

  @override
  String get circuitGenerated => 'Circuit Generated';

  @override
  String get usingYourOrchidAccount =>
      'Using your Orchid account, a single hop circuit has been generated. You may manage this from the circuit builder screen.';
}
