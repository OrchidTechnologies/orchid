// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class SHi extends S {
  SHi([String locale = 'hi']) : super(locale);

  @override
  String get orchidHop => 'ऑर्किड हॉप';

  @override
  String get orchidDisabled => 'ऑर्किड को अक्षम किया गया';

  @override
  String get trafficMonitoringOnly => 'केवल यातात पर निगरानी';

  @override
  String get orchidConnecting => 'ऑर्किड कनेकट कर रहा है';

  @override
  String get orchidDisconnecting => 'ऑर्किड डिसकनेक्ट हो रह है';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num हॉप कॉन्फिगर किए गए हैं',
      two: 'दो हॉप कॉन्फिगर किए गए हैं',
      one: 'एक हॉप कॉन्फिगर किया गया है',
      zero: 'कोई भी हॉप कॉन्फिगर नहीं किए गए हैं',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'हटाएँ';

  @override
  String get orchid => 'ऑर्किड';

  @override
  String get openVPN => 'मुक्त-वीपीएन';

  @override
  String get hops => 'हॉप';

  @override
  String get traffic => 'यातायात';

  @override
  String get curation => 'क्यूरेशन';

  @override
  String get signerKey => 'साइनर कुंजी';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get paste => 'चिपकाएँ';

  @override
  String get deposit => 'जमा';

  @override
  String get curator => 'क्यूरेटर';

  @override
  String get ok => 'ठीक है';

  @override
  String get settingsButtonTitle => 'सेटिंग';

  @override
  String get confirmThisAction => 'इस कार्य की पुष्टि करें';

  @override
  String get cancelButtonTitle => 'रद्द करें';

  @override
  String get changesWillTakeEffectInstruction =>
      'परिवर्तन तक दिखाई देंगे जब वीपीएन को दुबारा शुरू किया जाएगा।';

  @override
  String get saved => 'सहेज लिया';

  @override
  String get configurationSaved => 'कॉन्फिगरेशन को सहेज लिया गया';

  @override
  String get whoops => 'शाबाश';

  @override
  String get configurationFailedInstruction =>
      'कॉन्फिगरेशन को सहेजा नहीं जा सका। कृपया उसके वाक्य-विन्यास को जाँचें और दुबारा कोशिश करें।';

  @override
  String get addHop => 'हॉप जोड़ें';

  @override
  String get scan => 'स्कैन करें';

  @override
  String get invalidQRCode => 'अमान्य क्यूआर कोड';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'आपने जिस क्यूआर कोड को स्कैन किया है, उसमें एक मान्य खाता कॉन्फिगरेशन नहीं है।';

  @override
  String get invalidCode => 'अमान्य कोड';

  @override
  String get theCodeYouPastedDoesNot =>
      'आपने जो कोड चिपकाया है, उसमें एक मान्य खाता कॉन्फिगरेशन नहीं है।';

  @override
  String get openVPNHop => 'मुक्त-वीपीएन हॉप';

  @override
  String get username => 'उपयोगकर्ता नाम';

  @override
  String get password => 'पासवर्ड';

  @override
  String get config => 'कॉन्फिग';

  @override
  String get pasteYourOVPN => 'अपनी ओवीपीएन कॉन्फिग फाइल को यहाँ चिपकाएँ';

  @override
  String get enterYourCredentials => 'अपने प्रत्यायन दर्ज करें';

  @override
  String get enterLoginInformationInstruction =>
      'ऊपर अपने वीपीएन प्रदाता के लिए लॉगिन जानकारी दर्ज करें। फिर अपने प्रदाता की ओपनवीपीएन कॉन्फिग फाइल की सामग्री को प्रदान किए गए स्थान में चिपकाएँ।';

  @override
  String get save => 'सहेजें';

  @override
  String get help => 'मदद';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get openSourceLicenses => 'मुक्त स्रोत लाइसेंस';

  @override
  String get settings => 'सेटिंग';

  @override
  String get version => 'संस्करण';

  @override
  String get noVersion => 'कोई संस्करण नहीं है';

  @override
  String get orchidOverview => 'ऑर्किड सारांश';

  @override
  String get defaultCurator => 'डिफॉल्ट क्यूरेटर';

  @override
  String get queryBalances => 'शेष राशि के बारे में पूछें';

  @override
  String get reset => 'रीसेट करें';

  @override
  String get manageConfiguration => 'कॉन्फिगरेशन को प्रबंधित करें';

  @override
  String get warningThesefeature =>
      'चेतावनी: ये सुविधाएँ केवल उन्नत उपयोगकर्ताओं के लिए हैं।  कृपया सभी निर्देशों को पढ़ें।';

  @override
  String get exportHopsConfiguration => 'हॉप्स कॉन्फिगरेशन को निर्यात करें';

  @override
  String get export => 'निर्यात करें';

  @override
  String get warningExportedConfiguration =>
      'चेतावनी: निर्यात कॉन्फिगरेशन में निर्यात किए गए हॉपों के लिए साइनर निजी कुंजी रहस्य शामिल हैं।  निजी कुंजियों का खुलासा करने पर आप आर्किड खातों से जुड़ी सभी निधियों को जोखिम में डाल देंगे।';

  @override
  String get importHopsConfiguration => 'हॉप कॉन्फिगरेशन आयात करें';

  @override
  String get import => 'आयात करें';

  @override
  String get warningImportedConfiguration =>
      'चेतावनी: आयातित कॉन्फिगरेशन आपके द्वारा ऐप में बनाए गए सभी मौजूदा हॉपों का स्थान ले लेगा।  इस उपकरण पर पहले से उत्पन्न या आयातित सिग्नर कुंजी को बनाए रखा जाएगा और नए हॉप बनाने के लिए वह सुलभ रहेगा, हालांकि ओपनवीपीएन हॉप कॉन्फिगरेशन सहित अन्य सभी कॉन्फिगरेशन खो जाएँगे।';

  @override
  String get configuration => 'कॉन्फिगरेशन';

  @override
  String get saveButtonTitle => 'सहेजें';

  @override
  String get search => 'खोजें';

  @override
  String get newContent => 'नई सामग्री';

  @override
  String get clear => 'साफ करें';

  @override
  String get connectionDetail => 'कनेक्शन विवरण';

  @override
  String get host => 'मेजबान';

  @override
  String get time => 'समय';

  @override
  String get sourcePort => 'स्रोत पोर्ट';

  @override
  String get destination => 'गंतव्य';

  @override
  String get destinationPort => 'गंतव्य पोर्ट';

  @override
  String get generateNewKey => 'नई कुंजी निर्मित करें';

  @override
  String get importKey => 'कुंजी आयात करें';

  @override
  String get nothingToDisplayYet =>
      'अभी दिखाने के लिए कुछ भी नहीं है। जब कुछ दिखाने के लिए होगा, तब यातायात यहाँ दिखाई देगा।';

  @override
  String get disconnecting => 'डिसकनेक्ट कर रहे हैं...';

  @override
  String get connecting => 'कनेक्ट कर रहे हैं...';

  @override
  String get pushToConnect => 'कनेक्ट करने के लिए पुश करें।';

  @override
  String get orchidIsRunning => 'ऑर्किड चल रहा है!';

  @override
  String get pacPurchaseWaiting => 'खरीद प्रतीक्षा में है';

  @override
  String get retry => 'दुबारा कोशिश करें';

  @override
  String get getHelpResolvingIssue => 'इस समस्या को सुलटाने के लिए मदद पाएँ।';

  @override
  String get copyDebugInfo => 'डीबग जानकारी को कॉपी करें';

  @override
  String get contactOrchid => 'ऑर्किड से संपर्क करें';

  @override
  String get remove => 'हटाएँ';

  @override
  String get deleteTransaction => 'लेन-देन को हटाएँ';

  @override
  String get clearThisInProgressTransactionExplain =>
      'इस चालू लेन-देन को साफ करें। इससे आपके इन-एप खरीद के लिए धन-वापसी नहीं होगी। इस मामले को सुलटाने के लिए आपको ऑर्किड से संपर्क करना होगा।';

  @override
  String get preparingPurchase => 'खरीद की तैयारी कर रहे हैं';

  @override
  String get retryingPurchasedPAC => 'खरीदने की दुबारा कोशिश कर रहे हैं';

  @override
  String get retryPurchasedPAC => 'खरीदने की दुबारा कोशिश करें';

  @override
  String get purchaseError => 'खरीद त्रुटि';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'खरीदे समय एक त्रुटि हुई। कृपया ऑर्किड समर्थन से संपर्क करें।';

  @override
  String get importAnOrchidAccount => 'एक ऑर्किड खाता आयात करें';

  @override
  String get buyCredits => 'क्रेडिट खरीदें';

  @override
  String get linkAnOrchidAccount => 'ऑर्किड खाते को लिंक करें';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'हमें खेद है लेकिन यह खरीद एक्सेस क्रेडिट के लिए दैनिक खरीद सीमा से अधिक होगी।  कृपया बाद में दुबारा कोशिश करें।';

  @override
  String get marketStats => 'बाजर के आँकड़े';

  @override
  String get balanceTooLow => 'शेष राशि बहुत कम है';

  @override
  String get depositSizeTooSmall => 'जमा राशि की मात्रा बहुत कम है';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'आपका अधिकतम टिकट मूल्य वर्तमान में आपकी शेष राशि द्वारा सीमित है';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'आपका अधिकतम टिकट मूल्य वर्तमान में आपकी जमा राशि से सीमित है';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'अपने खाते की शेष राशि में ओएक्सटी जोड़ने पर विचार करें।';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'अपनी जमा राशि में ओएक्सटी जोड़ने या अपनी शेष राशि से धन ले जाने पर विचार करें ।';

  @override
  String get prices => 'कीमतें';

  @override
  String get ticketValue => 'टिकट मूल्य';

  @override
  String get costToRedeem => 'भुनाने की लागत:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'इस मुद्दे पर मदद के लिए दस्तावेजों को देखें।';

  @override
  String get goodForBrowsingAndLightActivity =>
      'ब्राउस करने और हल्की गतिविधि के लिए अच्छा है';

  @override
  String get learnMore => 'ज्यादा जानें।';

  @override
  String get connect => 'कनेक्ट करें';

  @override
  String get disconnect => 'डिसकनेक्ट करें';

  @override
  String get wireguardHop => 'वायर-गार्ड®️ हॉप';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'अपने वायर-गार्ड®️ कॉन्फिग को यहाँ चिपकाएँ';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'अपने वायरगार्ड के®️ प्रदाता के लिए क्रेडेंशियल जानकारी को ऊपर की जगह में चिपकाएँ।';

  @override
  String get wireguard => 'वायर-गार्ड®️';

  @override
  String get clearAllLogData => 'सभी लॉग डेटा को साफ करें?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'ऐप छोड़ते समय यह डिबग लॉग बना नहीं रहेगा और मिट जाएगा।';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'उसमें रहस्य या निजी पहचान को संभव बनाने वाली जानकारी हो सकती है।';

  @override
  String get loggingEnabled => 'लॉगिन सक्षम कर दिया गया';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get logging => 'लॉग कर रहे हैं';

  @override
  String get loading => 'लोड कर रहे हैं...';

  @override
  String get ethPrice => 'ईटीएच मूल्य:';

  @override
  String get oxtPrice => 'ऑक्सटी मूल्य:';

  @override
  String get gasPrice => 'नेटवर्क शुल्क:';

  @override
  String get maxFaceValue => 'अधिकतम अंकित मूल्य:';

  @override
  String get confirmDelete => 'हटाने की पुष्टि करें';

  @override
  String get enterOpenvpnConfig => 'ओपनवीपीएन कॉन्फिग दर्ज करें';

  @override
  String get enterWireguardConfig => 'वायर-गार्ड®️ कॉन्फिग दर्ज करें';

  @override
  String get starting => 'शुरू कर रहे हैं...';

  @override
  String get legal => 'कानूनी';

  @override
  String get whatsNewInOrchid => 'ऑर्किड में क्या नया है';

  @override
  String get orchidIsOnXdai => 'ऑर्किड एक्स-डाई में आ गया है!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'अब आप एक्स-डाई में ऑर्किड क्रेडिट खरीद सकते हैं! \$1 जितने कम दामों पर वीपीएन का उपयोग करना शुरू करें।';

  @override
  String get xdaiAccountsForPastPurchases =>
      'पिछली खरीदों के लिए एक्स-डाई खाते';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'आज से पहले की गई किसी भी इन-एप खरीद के लिए, एक्स-डाई निधियों को उसी खाता-कुंजी में जोड़ दिया गया है। बैंडविड्थ हमारी बदौलत!';

  @override
  String get newInterface => 'नया इंटरफेस';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'अब खाते उनसे संबंधित ऑर्किड पते के तहत व्यवस्थित किए गए हैं।';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'होम स्क्रीन पर अपने सक्रिय खाते की शेष राशि और बैंडविड्थ दाम देखें।';

  @override
  String get seeOrchidcomForHelp => 'मदद के लिए orchid.com देखें।';

  @override
  String get payPerUseVpnService => 'उपयोग के अनुसार भुगतान करें वीपीएन सेवा';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'सदस्यता नहीं है, क्रेडिट कभी समाप्त नहीं होते';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'खाते को असंख्य उपकरणों के साथ साझा करें';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'ऑर्किड स्टोर अस्थायी रूप से उपलब्ध नहीं है। चंद मिनटों के बाद दुबारा कोशिश करें।';

  @override
  String get talkingToPacServer => 'ऑर्किड खाता सर्वर के साथ बात कर रहे हैं';

  @override
  String get advancedConfiguration => 'उन्नत विन्यास';

  @override
  String get newWord => 'नया';

  @override
  String get copied => 'कॉपी कर लिया';

  @override
  String get efficiency => 'कार्यदक्षता';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'न्यूनतम टिकट उपलब्ध हैं: $tickets';
  }

  @override
  String get transactionSentToBlockchain =>
      'लेन-देन को ब्लाॉकचेइन को भेज दिया गया है';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'आपकी खरीद पूरी हो गई है और इसे अब एक्स-डाई द्वारा प्रक्रमित किया जा रहा है, जिसमें एक मिनट का या कभी-कभी उससे ज्यादा समय लग सकता है। ताजा करने के लिए नीचे खीचें और अद्यतित शेष राशि के साथ आपका खाता नीचे दिखाई देगा।';

  @override
  String get copyReceipt => 'पावती को कॉपी करें';

  @override
  String get manageAccounts => 'खातों को प्रबंधित करें';

  @override
  String get configurationManagement => 'विन्यास प्रबंधन';

  @override
  String get exportThisOrchidKey => 'इस ऑर्किड कुंजी को निर्यात करें';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'नीचे इस कुंजी के साथ संबंधित सभी ऑर्किड खातों के लिए एक क्यूआर कोड और पाठ दिया गया है।';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'इस ऑर्किड अस्मिता से संबंधित सभी ऑर्किड खातों को साझा करने के लिए इस कुंजी को दूसरे उपकरण में आयाता करें।';

  @override
  String get orchidAccountInUse => 'ऑर्कड खाता उपयोग में है';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'इस ऑर्किड खाते का उपयोग हो रहा है और उसे हटाया नहीं जा सकता है।';

  @override
  String get pullToRefresh => 'ताजा करने के लिए खींचें।';

  @override
  String get balance => 'शेष';

  @override
  String get active => 'सक्रिय';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'उस कुंजी से संबंधित सभी ऑर्किड खातों को आयात करने के लिए क्लिपबोर्ड से इस ऑर्किड कुंजी को चिपकाएँ।';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'उस कुंजी से संबंधित सभी ऑर्किड खातों को आयात करने के लिए क्लिपबोर्ड से स्कैन करें या ऑर्किड कुंजी को चिपकाएँ।';

  @override
  String get account => 'खाता';

  @override
  String get transactions => 'लेन-देन';

  @override
  String get weRecommendBackingItUp =>
      'हमारा सुझाव है कि <link>इसका बैक-अप ले लें</link>।';

  @override
  String get copiedOrchidIdentity => 'ऑर्किड पहचान को कॉपी कर लिया';

  @override
  String get thisIsNotAWalletAddress => 'यह वॉलेट का पता नहीं है।';

  @override
  String get doNotSendTokensToThisAddress => 'इस पते को टोकन नहीं भेजें।';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'आपकी ऑर्किड पहचान आपको नेटवर्क पर अद्वितीय रूप से पहचानती है।';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'अपनी <link>ऑर्किड पहचान</link> के बारे में अधिक जानें।';

  @override
  String get analyzingYourConnections =>
      'आपके कनेक्शनों का विश्लेषण कर रहे हैं';

  @override
  String get analyzeYourConnections => 'अपने कनेक्शनों का विश्लेषण करें';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'नेटवर्क विश्लेषण आपके डिवाइस की वीपीएन सुविधा का उपयोग करके पैकटों को ग्रहण करता है और आपकी यातायात का विश्लेषण करता है।';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'नेटवर्क विश्लेषण के लिए वीपीएन अनुमतियों की आवश्यकता होती है, लेकिन यह अपने आप में आपके डेटा की रक्षा नहीं करता है, नही आपके आईपी पते को छिपाता है।';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'नेटवर्क गोपनीयता का लाभ लेने के लिए आपको मुख्य स्क्रीन से वीपीएन कनेक्शन को कॉन्फिगर करके उसे सक्रिय करना होगा।';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'इस सुविधा को चालू करने पर ऑर्किड द्वारा बैटरी का उपयोग बढ़ जाएगा।';

  @override
  String get useAnOrchidAccount => 'एक ऑर्किड खाते का उपयोग करें';

  @override
  String get pasteAddress => 'पते को चिपकाएँ';

  @override
  String get chooseAddress => 'पता चुनें';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'इस हॉप के साथ उपयोग करने के लिए एक ऑर्किड खाता चुनें।';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'यदि आपको नीचे अपना खाता नहीं दिखें, तो आप खाता प्रबंधक का उपयोग करके एक नए खाते का आयात कर सकते हैं, उसे खरीद सकते हैं या उसे निर्मित कर सकते हैं।';

  @override
  String get selectAnOrchidAccount => 'एक ऑर्किड खाता चुनें';

  @override
  String get takeMeToTheAccountManager => 'मुझे खाता प्रबंधक के पास ले जाएँ';

  @override
  String get funderAccount => 'निधिदाता खाता';

  @override
  String get orchidRunningAndAnalyzing =>
      'ऑर्किड चल रहा है और विश्लेषण कर रहा है';

  @override
  String get startingVpn => '(वीपीएन को शुरू कर रहे हैं)';

  @override
  String get disconnectingVpn => '(वीपीएन को अलग कर रहे हैं)';

  @override
  String get orchidAnalyzingTraffic => 'ऑर्किड यातायात का विश्लेषण कर रहा है';

  @override
  String get vpnConnectedButNotRouting =>
      '(वीपीएन जुड़ गया है लेकिन वह रूटिंग नहीं कर रहा है)';

  @override
  String get restarting => 'पुनरारंभ कर रहे हैं';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'निगरानी की स्थिति को बदलने के लिए वीपीएन को दुबारा चालू करना होगा, जिससे कुछ समय के लिए गोपनीय रक्षण में बाधा आएगी।';

  @override
  String get confirmRestart => 'पुनरारंभ की पुष्टि करें';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'औसत मूल्य $price अमेरिकी डॉलर प्रति जीबी है';
  }

  @override
  String get myOrchidConfig => 'मेरा ऑर्किड कॉन्फिग';

  @override
  String get noAccountSelected => 'कोई खाता नहीं चुना गया है';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get tickets => 'टिकट';

  @override
  String get accounts => 'खाते';

  @override
  String get orchidIdentity => 'ऑर्किड पहचान';

  @override
  String get addFunds => 'निधियाँ जोड़ें';

  @override
  String get addFunds2 => 'धन जोड़ें';

  @override
  String get gb => 'जीबी';

  @override
  String get usdgb => 'USD/GB';

  @override
  String get hop => 'हॉप';

  @override
  String get circuit => 'परिपथ';

  @override
  String get clearAllAnalysisData => 'सभी विश्लेषण डेटा को साफ करें?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'इस कार्रवाई से पहले के सभी यातायात कनेक्शन विश्लेषण आँकड़े साफ हो जाएँगे।';

  @override
  String get clearAll => 'सबको साफ करें';

  @override
  String get stopAnalysis => 'विश्लेषण रोकें';

  @override
  String get startAnalysis => 'विश्लेषण शुरू करें';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'आर्किड खातों में 24/7 ग्राहक समर्थन और असीमित डिवाइस शामिल हैं और वह <link2>डाय क्रिप्टो-मुद्रा</link2>द्वारा समर्थित है।';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'खरीदे गए खाते अनन्य रूप से हमारे <link1>प्राथमिकतापूर्ण प्रदाताओं से</link1> कनेक्ट होते हैं।';

  @override
  String get refundPolicyCoveredByAppStores => 'ऐप स्टोर की धनवापसी नीति।';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'ऑर्किड इस समय ऐप में से की गई खरीदारियों को दर्शा नहीं पा रहा है।';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'कृपया पुष्टि करें कि यह डिवाइस ऐप से खरीदारी का समर्थन करता है और उसे इसके लिए कॉन्फिगर किया गया है।';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'कृपया पुष्टि करें कि यह डिवाइस ऐप से खरीदारी को समर्थित करता है और उसे इसके लिए कॉन्फिगर किया गया है, अथवा हमारे विकेंद्रीकृत <link>खाता प्रबंधन</link> प्रणाली का उपयोग करें।';

  @override
  String get buy => 'खरीदें';

  @override
  String get gbApproximately12 => '12जीबी (लगभग)';

  @override
  String get gbApproximately60 => '60जीबी (लगभग)';

  @override
  String get gbApproximately240 => '240जीबी (लगभग)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'मध्यम अवधि के व्यक्तिगत उपयोग हेतु, जिसमें ब्राउजिंग और हल्की स्ट्रीमिंग शामिल है, यह आदर्श आमाप है';

  @override
  String get mostPopular => 'सबसे ज्यादा लोकप्रिय!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'बैंडविड्थ का बहुत अधिक उपयोग करने वाला दीर्घकालिक उपयोग या साझे खाते।';

  @override
  String get total => 'कुल';

  @override
  String get pausingAllTraffic =>
      'सभी यातायात को अस्थायी तौर पर रोक रहे हैं...';

  @override
  String get queryingEthereumForARandom =>
      'एक यादृच्छिक प्रदाता के लिए इथेरियम से पूछताछ कर रहे हैं...';

  @override
  String get quickFundAnAccount => 'खाते में तेजी से पैसा डालें!';

  @override
  String get accountFound => 'खाता मिला';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'हमें आपकी पहचानों से संबंधित एक खाता मिला और उसके लिए हमने एक अकेला हॉप ऑर्किड परिपथ निर्मित किया। अब आप वीपीएन का उपयोग करने के लिए तैयार हैं।';

  @override
  String get welcomeToOrchid => 'ऑर्किड में आपका स्वागत है!';

  @override
  String get fundYourAccount => 'अपने खाते में पैसा डालें';

  @override
  String get processing => 'संसाधित किया जा रहा है...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'सदस्यता-मुक्त, उपयोग करते हुए भुगतान किया जाने वाला, विकेंद्रीकृत, मुक्त स्रोत वीपीएन सेवा।';

  @override
  String getStartedFor1(String smallAmount) {
    return '$smallAmount से शुरुआत करें';
  }

  @override
  String get importAccount => 'खाते को आयातित करें';

  @override
  String get illDoThisLater => 'मैं यह बाद में कर लूँगा';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'अपने साझा करने योग्य, पुनर्भरण योग्य ऑर्किड खाते के लिए वीपीएन क्रेडिट खरीदकर नेटवर्क के <link1>पसंदीदा प्रदाताओं</link1> में से किसी एक के साथ अपने आप कनेक्ट हो जाएँ।';

  @override
  String get confirmPurchase => 'खरीद की पुष्टि करें';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'ऑर्किड खाते <link>xडीएआई क्रिप्टो-मुद्रा</link> द्वारा समर्थित वीपीएन क्रेडिटों का उपयोग करते हैं। इनमें शामिल हैं 24/7 ग्राहक समर्थन और असीमित डिवाइस साझाकरण। ये ऐप स्टोर धन-वापसी नीतियों के तहत आते हैं।';

  @override
  String get yourPurchaseIsInProgress => 'आपकी खरीद जारी है।';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'इस खरीद में अपेक्षा से अधिक समय लग रहा है। संभव है कि इसमें त्रुटि आ गई हो।';

  @override
  String get thisMayTakeAMinute => 'इसमें एक मिनट लगेगा...';

  @override
  String get vpnCredits => 'वीपीएन क्रेडिट';

  @override
  String get blockchainFee => 'ब्लॉकचेइन शुल्क';

  @override
  String get promotion => 'प्रोमोशन';

  @override
  String get showInAccountManager => 'खाता प्रबंधक में दिखाएँ';

  @override
  String get deleteThisOrchidIdentity => 'इस ऑर्किड पहचान को हटाएँ';

  @override
  String get chooseIdentity => 'पहचान चुनें';

  @override
  String get updatingAccounts => 'खातों को अद्यतित कर रहे हैं';

  @override
  String get trafficAnalysis => 'यातायात का विश्लेषण';

  @override
  String get accountManager => 'खाता प्रबंधक';

  @override
  String get circuitBuilder => 'परिपथ निर्माता';

  @override
  String get exitHop => 'हॉप से बाहर निकलें';

  @override
  String get entryHop => 'हॉप में प्रवेश करें';

  @override
  String get addNewHop => 'नया हॉप जोड़ें';

  @override
  String get newCircuitBuilder => 'नया परिपथ निर्माता!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'अब आप xडीएआई से मल्टी-हॉप ऑर्किड परिपथ के लिए भुगतान कर सकते हैं। मल्टी-हॉप इंटरफेस अब xडीएआई और ओएक्सटी ऑर्किड खातों का समर्थन करता है और अब भी ओपन-वीपीएन और वायरगार्ड कॉन्फिगों का समर्थन करता है, जिन्हें एक साथ पिरोकर एक ऑनियन पथ बनाया जा सकता है।';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'खाता प्रबंधक की जगह अपने कनेक्शन का प्रबंधन परिपथ निर्माता से करें। अब सभी कनेक्शन शून्य या इससे अधिक हॉपों का उपयोग करने परिपथ का उपयोग करते हैं। मौजूद कॉन्फिगरेशन को परिपर्थ निर्माता में स्थानांतरित कर दिया गया है।';

  @override
  String quickStartFor1(String smallAmount) {
    return '$smallAmount के लिए त्वरित शुरुआत';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'हमने होमस्क्रीन से ही एक ऑर्किड खाता खरीदने और एक अकेले हॉप परिपथ निर्मित करने की विधि जोड़ी है ताकि ऑनबोर्डिंग प्रक्रिया को अधिक छोटा बनाया जा सके।';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'ऑर्किड एक अद्वितीय मल्टी-हॉप या अनियन परिपथन ग्राहक समर्थक एकाधिक वीपीएन प्रोटोकॉल है। अब नीचे के समर्थित प्रोटोकॉलों में से हॉपों को शृंखलित करके अपने कनेक्शन को सेटअप कर सकते हैं।\n\nएक हॉप किसी भी सामान्य वीपीएन के समान है। तीन हॉप (उन्नत उपयोगकर्ताओं के लिए) क्लासिक अनियन परिपथन विकल्प है। शून्य हॉप बिना वीपीएन सुरंग के यातायात के विश्लेषण की सुविधा प्रदान करते हैं।';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'ओपन-वीपीएन और वायरगार्ड हॉपों को हटाने से आप उनसे संबंधित सभी क्रिडेन्शियल और कनेक्शन कॉन्फिगरेशन को खो देंगे। आगे बढ़ने से पहले सभी जानकारियों का बैंक-अप ले लें।';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'इसे पलटा नहीं जा सकेगा। इस पहचान को सहेजने के लिए रद्द करें को दबाएँ और निर्यात करें विकल्प का उपयोग करें।';

  @override
  String get unlockTime => 'अनलॉक समय';

  @override
  String get chooseChain => 'शृखला चुनें';

  @override
  String get unlocking => 'अनलॉक कर रहे हैं';

  @override
  String get unlocked => 'अनलॉक कर दिया';

  @override
  String get orchidTransaction => 'ऑर्किड लेन-देन';

  @override
  String get confirmations => 'पुष्टियाँ';

  @override
  String get pending => 'लंबित...';

  @override
  String get txHash => 'लेन-देन हैश:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'आपकी पूरी निधि आहरण के लिए उपलब्ध है।';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return 'आपकी $totalFunds समेकित निधि में से $maxWithdraw फिलहाल आहरण के लिए उपलब्ध है।';
  }

  @override
  String get alsoUnlockRemainingDeposit => 'बाकी के निक्षेप को भी अनलॉक करें';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'यदि आप पूर्ण राशि से कम राशि निर्दिष्ट करेंगे, तो पहले आपकी शेष राशि से निधि आहरित की जाएगी।';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'अतिरिक्त विकल्पों के लिए उन्न पैनल देखें।';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'यदि आप निक्षेप को अनलॉक करें विकल्प को चुनेंगे, तो यह लेन-देन तुरंत निर्दिष्ट राशि को आपकी शेष राशि से आहरित कर देगा और साथ ही आपके बाकी के निक्षेप को अनलॉक करने की प्रक्रिया को भी शुरू कर देगा।';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'निक्षेप निधियाँ अनलॉक होने के 24 घंटे बाद आहरण के लिए उपलब्ध हो जाती हैं।';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'अपने ऑर्किड खाते से अपने वर्तमान वॉलेट में निधियाँ आहरित करें।';

  @override
  String get withdrawAndUnlockFunds => 'निधियाँ आहरित और अनलॉक करें';

  @override
  String get withdrawFunds => 'निधियाँ आहरित करें';

  @override
  String get withdrawFunds2 => 'धन निकालना';

  @override
  String get withdraw => 'आहरित करें';

  @override
  String get submitTransaction => 'लेन-देन जमा करें';

  @override
  String get move => 'स्थानांतरित करें';

  @override
  String get now => 'अभी';

  @override
  String get amount => 'राशि';

  @override
  String get available => 'उपलब्ध';

  @override
  String get select => 'चुनें';

  @override
  String get add => 'जोड़ें';

  @override
  String get balanceToDeposit => 'जमा करने के लिए शेष';

  @override
  String get depositToBalance => 'शेष में जमा करें';

  @override
  String get setWarnedAmount => 'चेतावनी राशि सेट करें';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'अपने ऑर्किड खाता शेष में निधियाँ जोड़ें और/या जमा करें।';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'अपने खाते का आमाप निर्धारित करने में मार्गदर्शन पाने के लिए <link>orchid.com</link> देखें';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'वर्तमान $tokenType पूर्व-प्राधिकरण: $amount';
  }

  @override
  String get noWallet => 'कोई वॉलेट नहीं है';

  @override
  String get noWalletOrBrowserNotSupported =>
      'कोई वॉलेट नहीं है या ब्राउजर समर्थित नहीं है।';

  @override
  String get error => 'त्रुटि';

  @override
  String get failedToConnectToWalletconnect => 'वॉलेटकनेक्ट से जुड़ नहीं सकें।';

  @override
  String get unknownChain => 'अज्ञात शृंखला';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'ऑर्किड खाता प्रबंधक अभी इस शृंखला को समर्थित नहीं करता है।';

  @override
  String get orchidIsntOnThisChain => 'ऑर्किड इस शृंखला में मौजूद नहीं है।';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'ऑर्किड अनुबंध को इस शृंखला में अभी परिनियोजित नहीं किया गया है।';

  @override
  String get moveFunds => 'निधियों को स्थानांतरित करें';

  @override
  String get moveFunds2 => 'फंड ले जाएँ';

  @override
  String get lockUnlock => 'लॉक / अनलॉक करें';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return '$amount के आपके निक्षेप को अनलॉक किया गया।';
  }

  @override
  String get locked => 'लॉक किया गया';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return '$amount के आपके निक्षेप को $unlockingOrUnlocked किया गया।';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'यह निधि आहरण के लिए \$$time को उपलब्ध हो जाएगी।';
  }

  @override
  String get lockDeposit => 'निक्षेप को लॉक करें';

  @override
  String get unlockDeposit => 'निक्षेप को अनलॉक करें';

  @override
  String get advanced => 'उन्नत';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>ऑर्किड खातों के बारे में अधिक जानें</link>।';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return '$efficiency की कार्यदक्षता और $num मूल्य के टिकटों के साथ एक ऑर्किड खाता निर्मित करने की अनुमानित लागत।';
  }

  @override
  String get chain => 'शृंखला';

  @override
  String get token => 'टोकन';

  @override
  String get minDeposit => 'न्यूनतम निक्षेप';

  @override
  String get minBalance => 'न्यूनतम शेष';

  @override
  String get fundFee => 'निधि शुल्क';

  @override
  String get withdrawFee => 'आहरण शुल्क';

  @override
  String get tokenValues => 'टोकन मान';

  @override
  String get usdPrices => 'अमेरिकी डॉलर में कीमतें';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'एक चेतावनी-युक्त निक्षेप राशि सेट करना निक्षेप राशि को आहरित करने के लिए आवश्यक 24 घंटे की प्रतीक्षा अवधि का आरंभ करता है।';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'इस अवधि के दौरान निधियाँ ऑर्किड नेटवर्क पर एक मान्य निक्षेप के रूप में उपलब्ध नहीं रहती हैं।';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'चेतावनी राशि को कम करके निधियों को किसी भी समय पुनः लॉक किया जा सकता है।';

  @override
  String get warn => 'चेतावनी';

  @override
  String get totalWarnedAmount => 'कुल चेतावनी राशि';

  @override
  String get newIdentity => 'नई पहचान';

  @override
  String get importIdentity => 'पहचान आयातित करें';

  @override
  String get exportIdentity => 'पहचान निर्यात करें';

  @override
  String get deleteIdentity => 'पहचान हटाएँ';

  @override
  String get importOrchidIdentity => 'ऑर्किड पहचान आयात करें';

  @override
  String get funderAddress => 'वित्त-पोषक का पता';

  @override
  String get contract => 'अनुबंध';

  @override
  String get txFee => 'लेन-देन शुल्क';

  @override
  String get show => 'दिखाएँ';

  @override
  String get rpc => 'आरपीसी';

  @override
  String get errors => 'त्रुटियाँ';

  @override
  String get lastHour => 'अंतिम घंटा';

  @override
  String get chainSettings => 'शृंखला सेटिंग';

  @override
  String get price => 'कीमत';

  @override
  String get failed => 'विफल हुआ';

  @override
  String get fetchGasPrice => 'गैस लागत प्राप्त करें';

  @override
  String get fetchLotteryPot => 'लॉटरी पॉट ले आएँ';

  @override
  String get lines => 'पंक्तियाँ';

  @override
  String get filtered => 'छाँटा गया';

  @override
  String get backUpYourIdentity => 'अपनी पहचान का बैकअप लें';

  @override
  String get accountSetUp => 'खाता स्थापित करना';

  @override
  String get setUpAccount => 'खाता सेट करें';

  @override
  String get generateIdentity => 'पहचान उत्पन्न करें';

  @override
  String get enterAnExistingOrchidIdentity =>
      'एक मौजूदा <account_link>आर्किड पहचान</account_link>दर्ज करें';

  @override
  String get pasteTheWeb3WalletAddress =>
      'नीचे दिए गए वेब3 वॉलेट पते को पेस्ट करें जिसका उपयोग आप अपने खाते में निधि लगाने के लिए करेंगे।';

  @override
  String get funderWalletAddress => 'फंडर वॉलेट का पता';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'आपका आर्किड पहचान सार्वजनिक पता';

  @override
  String get continueButton => 'जारी रहना';

  @override
  String get yesIHaveSavedACopyOf =>
      'हां, मैंने अपनी निजी कुंजी की एक प्रति कहीं सुरक्षित रख ली है।';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'अपनी आर्किड पहचान <bold>निजी कुंजी</bold>का बैक अप लें। इस पहचान और सभी संबद्ध खातों को साझा करने, आयात करने या पुनर्स्थापित करने के लिए आपको इस कुंजी की आवश्यकता होगी।';

  @override
  String get locked1 => 'बंद';

  @override
  String get unlockDeposit1 => 'जमा अनलॉक करें';

  @override
  String get changeWarnedAmountTo => 'चेतावनी दी गई राशि को बदलें';

  @override
  String get setWarnedAmountTo => 'चेतावनी राशि को इस पर सेट करें';

  @override
  String get currentWarnedAmount => 'वर्तमान चेतावनी राशि';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'सभी चेतावनी दी गई धनराशि तब तक लॉक रहेगी जब तक';

  @override
  String get balanceToDeposit1 => 'जमा करने के लिए शेष राशि';

  @override
  String get depositToBalance1 => 'शेष राशि में जमा करें';

  @override
  String get advanced1 => 'उन्नत';

  @override
  String get add1 => 'जोड़ना';

  @override
  String get lockUnlock1 => 'लॉक करो लॉक खोलो';

  @override
  String get viewLogs => 'लॉग्स को देखें';

  @override
  String get language => 'भाषा';

  @override
  String get systemDefault => 'प्रणालीगत चूक';

  @override
  String get identiconStyle => 'पहचान शैली';

  @override
  String get blockies => 'ब्लॉकियां';

  @override
  String get jazzicon => 'जैज़िकॉन';

  @override
  String get contractVersion => 'अनुबंध संस्करण';

  @override
  String get version0 => 'संस्करण 0';

  @override
  String get version1 => 'संस्करण 1';

  @override
  String get connectedWithMetamask => 'Metamask . के साथ जुड़ा हुआ है';

  @override
  String get blockExplorer => 'ब्लॉक एक्सप्लोरर';

  @override
  String get tapToMinimize => 'छोटा करने के लिए टैप करें';

  @override
  String get connectWallet => 'बटुआ कनेक्ट करें';

  @override
  String get checkWallet => 'वॉलेट चेक करें';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'लंबित अनुरोध के लिए अपना वॉलेट ऐप या एक्सटेंशन देखें।';

  @override
  String get test => 'परीक्षा';

  @override
  String get chainName => 'श्रृंखला का नाम';

  @override
  String get rpcUrl => 'आरपीसी यूआरएल';

  @override
  String get tokenPrice => 'टोकन मूल्य';

  @override
  String get tokenPriceUsd => 'टोकन मूल्य USD';

  @override
  String get addChain => 'श्रृंखला जोड़ें';

  @override
  String get deleteChainQuestion => 'चेन मिटाएं?';

  @override
  String get deleteUserConfiguredChain =>
      'उपयोगकर्ता द्वारा कॉन्फ़िगर की गई श्रृंखला हटाएं';

  @override
  String get fundContractDeployer => 'फंड अनुबंध नियोक्ता';

  @override
  String get deploySingletonFactory => 'सिंगलटन फैक्ट्री तैनात करें';

  @override
  String get deployContract => 'अनुबंध तैनात करें';

  @override
  String get about => 'के बारे में';

  @override
  String get dappVersion => 'डैप संस्करण';

  @override
  String get viewContractOnEtherscan => 'इथरस्कैन पर अनुबंध देखें';

  @override
  String get viewContractOnGithub => 'गीथूब पर अनुबंध देखें';

  @override
  String get accountChanges => 'खाता परिवर्तन';

  @override
  String get name => 'नाम';

  @override
  String get step1 =>
      '<bold>चरण 1.</bold> ERC-20 वॉलेट को <link>पर्याप्त टोकन</link> के साथ कनेक्ट करें।';

  @override
  String get step2 =>
      '<bold>चरण 2.</bold> खाते प्रबंधित करें और फिर पते पर टैप करके आर्किड ऐप से आर्किड पहचान की प्रतिलिपि बनाएँ।';

  @override
  String get connectOrCreate => 'कनेक्ट करें या आर्किड खाता बनाएं';

  @override
  String get lockDeposit2 => 'ताला जमा';

  @override
  String get unlockDeposit2 => 'जमा अनलॉक करें';

  @override
  String get enterYourWeb3 => 'अपना वेब3 वॉलेट पता दर्ज करें।';

  @override
  String get purchaseComplete => 'खरीदारी पूर्ण';

  @override
  String get generateNewIdentity => 'एक नई पहचान बनाना';

  @override
  String get copyIdentity => 'कॉपी आइडेंटिटी';

  @override
  String get yourPurchaseIsComplete =>
      'आपकी खरीदारी पूरी हो गई है और अब xDai ब्लॉकचेन द्वारा संसाधित की जा रही है, जिसमें कुछ मिनट लग सकते हैं। इस खाते का उपयोग करके आपके लिए एक डिफ़ॉल्ट सर्किट तैयार किया गया है। आप होम स्क्रीन पर या खाता प्रबंधक में उपलब्ध शेष राशि की निगरानी कर सकते हैं।';

  @override
  String get circuitGenerated => 'सर्किट जनरेट किया गया';

  @override
  String get usingYourOrchidAccount =>
      'आपके ऑर्किड खाते का उपयोग करके, एक एकल हॉप सर्किट तैयार किया गया है। आप इसे सर्किट बिल्डर स्क्रीन से प्रबंधित कर सकते हैं।';
}
