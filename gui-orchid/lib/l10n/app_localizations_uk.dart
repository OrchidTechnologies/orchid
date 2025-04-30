// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class SUk extends S {
  SUk([String locale = 'uk']) : super(locale);

  @override
  String get orchidHop => 'Стрибок Orchid';

  @override
  String get orchidDisabled => 'Orchid деактивовано';

  @override
  String get trafficMonitoringOnly => 'Лише відстеження трафіку';

  @override
  String get orchidConnecting => 'Підключення Orchid';

  @override
  String get orchidDisconnecting => 'Відключення Orchid';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num стрибків сконфігуровано',
      two: 'два стрибки сконфігуровано',
      one: 'один стрибок сконфігуровано',
      zero: 'стрибків сконфігуровано',
      many: '$num стрибків сконфігуровано',
      few: '$num стрибки сконфігуровано',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Видалити';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Стрибки';

  @override
  String get traffic => 'Трафік';

  @override
  String get curation => 'Контроль';

  @override
  String get signerKey => 'Ключ підписувача';

  @override
  String get copy => 'Копіювати';

  @override
  String get paste => 'Вставити';

  @override
  String get deposit => 'Депозит';

  @override
  String get curator => 'Контролер';

  @override
  String get ok => 'ОК';

  @override
  String get settingsButtonTitle => 'НАЛАШТУВАННЯ';

  @override
  String get confirmThisAction => 'Підтвердьте цю дію';

  @override
  String get cancelButtonTitle => 'СКАСУВАТИ';

  @override
  String get changesWillTakeEffectInstruction =>
      'Зміни застосуватимуться після перезапуску VPN.';

  @override
  String get saved => 'Збережено';

  @override
  String get configurationSaved => 'Конфігурацію збережено';

  @override
  String get whoops => 'Помилка';

  @override
  String get configurationFailedInstruction =>
      'Не вдалося зберегти конфігурацію. Перевірте синтаксис і повторіть спробу.';

  @override
  String get addHop => 'Додати стрибок';

  @override
  String get scan => 'Сканувати';

  @override
  String get invalidQRCode => 'Недійсний QR-код';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'Сканований QR-код не містить дійсної конфігурації рахунку.';

  @override
  String get invalidCode => 'Недійсний код';

  @override
  String get theCodeYouPastedDoesNot =>
      'Вставлений код не містить дійсної конфігурації рахунку.';

  @override
  String get openVPNHop => 'Стрибок OpenVPN';

  @override
  String get username => 'Імʼя користувача';

  @override
  String get password => 'Пароль';

  @override
  String get config => 'Конфігурація';

  @override
  String get pasteYourOVPN => 'Вставте файл конфігурації OVPN тут';

  @override
  String get enterYourCredentials => 'Уведіть облікові дані';

  @override
  String get enterLoginInformationInstruction =>
      'Уведіть дані для входу в обліковий запис VPN-провайдера вище. Потім вставте вміст файлу конфігурації OpenVPN в надане поле.';

  @override
  String get save => 'Зберегти';

  @override
  String get help => 'Довідка';

  @override
  String get privacyPolicy => 'Політика конфіденційності';

  @override
  String get openSourceLicenses => 'Ліцензії з відкритим кодом';

  @override
  String get settings => 'Налаштування';

  @override
  String get version => 'Версія';

  @override
  String get noVersion => 'Без версії';

  @override
  String get orchidOverview => 'Огляд Orchid';

  @override
  String get defaultCurator => 'Контролер за замовченням';

  @override
  String get queryBalances => 'Запит балансів';

  @override
  String get reset => 'Скинути';

  @override
  String get manageConfiguration => 'Керування конфігурацією';

  @override
  String get warningThesefeature =>
      'Увага! Ці функції призначені лише для досвідчених користувачів. Прочитайте всі інструкції.';

  @override
  String get exportHopsConfiguration => 'Експорт конфігурації стрибків';

  @override
  String get export => 'Експорт';

  @override
  String get warningExportedConfiguration =>
      'Увага! Експортована конфігурація містить закриті приватні ключі підписувача для експортованих стрибків. Розкриття закритих ключів може призвести до втрати всіх коштів на пов’язаних облікових записах Orchid.';

  @override
  String get importHopsConfiguration => 'Імпорт конфігурації стрибків';

  @override
  String get import => 'Імпорт';

  @override
  String get warningImportedConfiguration =>
      'Увага! Імпортована конфігурація замінює будь-які наявні стрибки, що ви створили в додатку. Ключі підписувача, раніше згенеровані або імпортовані на цьому пристрої, зберігаються і можуть використовуватися для створення нових стрибків. Проте вся інша конфігурація, у тому числі конфігурація стрибку OpenVPN, буде втрачена.';

  @override
  String get configuration => 'Конфігурація';

  @override
  String get saveButtonTitle => 'ЗБЕРЕГТИ';

  @override
  String get search => 'Пошук';

  @override
  String get newContent => 'Новий контент';

  @override
  String get clear => 'Очистити';

  @override
  String get connectionDetail => 'Деталі підключення';

  @override
  String get host => 'Хост';

  @override
  String get time => 'Час';

  @override
  String get sourcePort => 'Початковий порт';

  @override
  String get destination => 'Призначення';

  @override
  String get destinationPort => 'Кінцевий порт';

  @override
  String get generateNewKey => 'Згенерувати новий ключ';

  @override
  String get importKey => 'Імпортувати ключ';

  @override
  String get nothingToDisplayYet =>
      'Дани відображатимуться, коли зʼявиться трафік.';

  @override
  String get disconnecting => 'Відключення...';

  @override
  String get connecting => 'Підключення...';

  @override
  String get pushToConnect => 'Натисніть для підключення.';

  @override
  String get orchidIsRunning => 'Orchid запущено!';

  @override
  String get pacPurchaseWaiting => 'Очікування покупки';

  @override
  String get retry => 'Повторити';

  @override
  String get getHelpResolvingIssue =>
      'Звернутися за довідкою для розвʼязання проблеми.';

  @override
  String get copyDebugInfo => 'Копіювати відомості налагодження';

  @override
  String get contactOrchid => 'Звʼязатися з Orchid';

  @override
  String get remove => 'Видалити';

  @override
  String get deleteTransaction => 'Видалити транзакцію';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Поточну транзакцію буде видалено, але вартість покупки в додатку не буде повернена. Щоб отримати повернення оплати, звертайтеся в Orchid.';

  @override
  String get preparingPurchase => 'Підготовка покупки';

  @override
  String get retryingPurchasedPAC => 'Повторна спроба покупки';

  @override
  String get retryPurchasedPAC => 'Повторити спробу покупки';

  @override
  String get purchaseError => 'Помилка покупки';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Виникла помилка покупки. Зверніться в підтримку Orchid.';

  @override
  String get importAnOrchidAccount => 'Імпортувати рахунок Orchid';

  @override
  String get buyCredits => 'Придбати кредити';

  @override
  String get linkAnOrchidAccount => 'Зв’язати рахунок Orchid';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'Вибачте, але ця покупка перевищить щоденний ліміт кредитів для доступу. Спробуйте пізніше.';

  @override
  String get marketStats => 'Статистика ринку';

  @override
  String get balanceTooLow => 'Надто низький баланс';

  @override
  String get depositSizeTooSmall => 'Недостатній розмір депозиту';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'Максимальна вартість квитка наразі обмежена вашим балансом';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'Максимальна вартість квитка наразі обмежена вашим депозитом';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Рекомендуємо додати OXT до балансу свого рахунку.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Рекомендуємо додати OXT до свого депозиту або переказати кошти на депозит із балансу.';

  @override
  String get prices => 'Ціни';

  @override
  String get ticketValue => 'Вартість квитка';

  @override
  String get costToRedeem => 'Вартість викупу:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Перегляньте довідкові документи стосовно цього питання.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Для перегляду та нечастого використання';

  @override
  String get learnMore => 'Докладніше';

  @override
  String get connect => 'Підключити';

  @override
  String get disconnect => 'Відключити';

  @override
  String get wireguardHop => 'Стрибок WireGuard®️';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Вставте файл конфігурації WireGuard®️ тут';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Вставте облікові дані постачальника WireGuard®️ у поле вище.';

  @override
  String get wireguard => 'WireGuard®️';

  @override
  String get clearAllLogData => 'Очистити всі дані журналу?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Цей журнал налагодження є тимчасовим і очищається під час виходу з додатка.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Він може містити секретну або особисту інформацію.';

  @override
  String get loggingEnabled => 'Журнал увімкнено';

  @override
  String get cancel => 'СКАСУВАТИ';

  @override
  String get logging => 'Ведення журналу';

  @override
  String get loading => 'Завантажується...';

  @override
  String get ethPrice => 'Ціна ETH:';

  @override
  String get oxtPrice => 'Ціна OXT:';

  @override
  String get gasPrice => 'Ціна газу:';

  @override
  String get maxFaceValue => 'Макс. номінал:';

  @override
  String get confirmDelete => 'Підтвердити видалення';

  @override
  String get enterOpenvpnConfig => 'Уведіть конфігурацію OpenVPN';

  @override
  String get enterWireguardConfig => 'Уведіть конфігурацію WireGuard®️';

  @override
  String get starting => 'Запуск...';

  @override
  String get legal => 'Юридичне';

  @override
  String get whatsNewInOrchid => 'Що нового в Orchid';

  @override
  String get orchidIsOnXdai => 'Orchid на xDai!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'Тепер можна купувати кредити Orchid на xDai! Почніть використовувати VPN лише за 1\$.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'На xDai обліковуються попередні покупки';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'Кошти в xDai, витрачені до сьогодні в додатку, додано до того самого ключа рахунку. Трафік — за наш рахунок!';

  @override
  String get newInterface => 'Новий інтерфейс';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'Рахунки тепер організовані відповідно до адреси Orchid, з якою вони пов’язані.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Перегляд балансу активного рахунку та вартості смуги пропускання на головному екрані.';

  @override
  String get seeOrchidcomForHelp => 'Див. довідку на orchid.com.';

  @override
  String get payPerUseVpnService =>
      'VPN-служба з платою за фактом використання';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Без передплати; кредити без строків дії';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Необмежена кількість пристроїв для одного облікового запису';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'Магазин Orchid тимчасово недоступний. Перевірте через кільки хвилин.';

  @override
  String get talkingToPacServer => 'Обмін даними зі сервером Orchid';

  @override
  String get advancedConfiguration => 'Розширена конфігурація';

  @override
  String get newWord => 'Додати';

  @override
  String get copied => 'Скопійовано';

  @override
  String get efficiency => 'Ефективність';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Мін. квитків доступно: $tickets';
  }

  @override
  String get transactionSentToBlockchain => 'Транзакцію надіслано в блокчейн';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Покупка завершена і зараз обробляється блокчейном xDai, що може зайняти кілька хвилин або іноді більше. Щоб переглянути оновлений баланс рахунку нижче, потягніть донизу.';

  @override
  String get copyReceipt => 'Копіювати квитанцію';

  @override
  String get manageAccounts => 'Керування рахунками';

  @override
  String get configurationManagement => 'Керування конфігурацією';

  @override
  String get exportThisOrchidKey => 'Експорт цього ключа Orchid';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'Нижче наведено QR-код і текст для всіх рахунків Orchid, пов’язаних із цим ключем.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Імпортуйте цей ключ на іншому пристрої, щоб надати доступ до всіх рахунків Orchid, пов’язаних із цим ідентифікатором Orchid.';

  @override
  String get orchidAccountInUse => 'Рахунок Orchid у користуванні';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Цей рахунок Orchid зараз використовується. Його видалення неможливо.';

  @override
  String get pullToRefresh => 'Потягніть для оновлення.';

  @override
  String get balance => 'Баланс';

  @override
  String get active => 'Активно';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Щоб імпортувати всі рахунки Orchid, пов’язані з цим ключем, вставте ключ Orchid із буфера.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Щоб імпортувати всі рахунки Orchid, пов’язані з цим ключем, зіскануйте або вставте ключ Orchid із буфера.';

  @override
  String get account => 'Рахунок';

  @override
  String get transactions => 'Транзакції';

  @override
  String get weRecommendBackingItUp =>
      'Рекомендуємо <link>створити резервну копію</link>.';

  @override
  String get copiedOrchidIdentity => 'Скопійовано ідентифікатор Orchid';

  @override
  String get thisIsNotAWalletAddress => 'Це не адреса гаманця.';

  @override
  String get doNotSendTokensToThisAddress =>
      'Не надсилайте токени на цю адресу.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Ваш ідентифікатор Orchid однозначно ідентифікує вас у мережі.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'Докладніше про <link>ідентифікацію Orchid</link>.';

  @override
  String get analyzingYourConnections => 'Аналіз підключень';

  @override
  String get analyzeYourConnections => 'Проаналізуйте підключення';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'Для аналізу мережі й трафіку використовується VPN вашого пристрою, через який отримуються пакети даних.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'Хоча для аналізу мережі потрібні дозволи на використання VPN, це само по собі не захищає дані та не приховує вашу IP-адресу.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Щоб забезпечити конфіденційність мережі, необхідно налаштувати та активувати VPN-з’єднання на головному екрані.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Внаслідок увімкнення цієї функції, додаток Orchid буде споживати більше заряду батареї.';

  @override
  String get useAnOrchidAccount => 'Використовувати рахунок Orchid';

  @override
  String get pasteAddress => 'Вставити адресу';

  @override
  String get chooseAddress => 'Вибрати адресу';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Вибрати рахунок Orchid для використання з цим стрибком.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Якщо ви не бачите рахунок нижче, можна скористатися диспетчером, щоб його імпортувати, придбати або створити новий.';

  @override
  String get selectAnOrchidAccount => 'Вибрати рахунок Orchid';

  @override
  String get takeMeToTheAccountManager => 'Перейти до диспетчера рахунків';

  @override
  String get funderAccount => 'Фінансувальний рахунок';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid виконує аналіз';

  @override
  String get startingVpn => '(Запуск VPN)';

  @override
  String get disconnectingVpn => '(Відключення VPN)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid аналізує трафік';

  @override
  String get vpnConnectedButNotRouting =>
      '(VPN підключено, але без маршрутизації)';

  @override
  String get restarting => 'Перезапуск';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'Щоб змінити статус моніторингу, потрібно перезапустити VPN, що може ненадовго призвести до порушення захисту конфіденційності.';

  @override
  String get confirmRestart => 'Підтвердити перезапуск';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'Середня ціна: $price USD за Гб';
  }

  @override
  String get myOrchidConfig => 'Моя конфігурація Orchid';

  @override
  String get noAccountSelected => 'Не вибрано рахунок';

  @override
  String get inactive => 'Неактивно';

  @override
  String get tickets => 'Квитки';

  @override
  String get accounts => 'Рахунки';

  @override
  String get orchidIdentity => 'Ідентифікатор Orchid';

  @override
  String get addFunds => 'ДОДАТИ КОШТИ';

  @override
  String get addFunds2 => 'Додати кошти';

  @override
  String get gb => 'Гб';

  @override
  String get usdgb => 'USD/Гб';

  @override
  String get hop => 'Стрибок';

  @override
  String get circuit => 'Ланцюжок';

  @override
  String get clearAllAnalysisData => 'Очистити всі дані аналізу?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Буде видалено всі раніше проаналізовані дані з’єднання трафіку.';

  @override
  String get clearAll => 'ОЧИСТИТИ ВСЕ';

  @override
  String get stopAnalysis => 'ЗУПИНИТИ АНАЛІЗ';

  @override
  String get startAnalysis => 'ПОЧАТИ АНАЛІЗ';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Рахунки Orchid передбачають цілодобову підтримку клієнтів, необмежену кількість пристроїв і забезпечені <link2>криптовалютою xDai</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Придбані рахунки підключаються лише до <link1>рекомендованих провайдерів</link1>.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Повернення коштів, згідно з відповідними правилами, забезпечують магазини додатків.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'Orchid зараз не може відображати покупки в додатку.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Переконайтеся, що цей пристрій підтримує покупки в додатку та налаштований для них.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Переконайтеся, що цей пристрій підтримує покупки в додатку та налаштований для них, або скористайтеся нашою децентралізованою системою <link>керування рахунками</link>.';

  @override
  String get buy => 'КУПИТИ';

  @override
  String get gbApproximately12 => '12 Гб (приблизно)';

  @override
  String get gbApproximately60 => '60 Гб (приблизно)';

  @override
  String get gbApproximately240 => '240 Гб (приблизно)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'Для середньострокового перегляду сайтів і легкого стримінгу одним користувачем.';

  @override
  String get mostPopular => 'Найпопулярніше!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Великий обсяг трафіку, довготривале використання або спільні рахунки.';

  @override
  String get total => 'Загалом';

  @override
  String get pausingAllTraffic => 'Призупинення всього трафіку...';

  @override
  String get queryingEthereumForARandom =>
      'Надсилаємо в Ethereum запит на довільного провайдера...';

  @override
  String get quickFundAnAccount => 'Швидке поповнення рахунку!';

  @override
  String get accountFound => 'Рахунок знайдено';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Ми знайшли рахунок, пов’язаний з вашими ідентифікаторами, і створили для нього ланцюжок Orchid з одним стрибком. Тепер можна використовувати VPN.';

  @override
  String get welcomeToOrchid => 'Вітаємо в Orchid!';

  @override
  String get fundYourAccount => 'Поповніть рахунок';

  @override
  String get processing => 'Обробляється...';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Децентралізований VPN-сервіс із відкритим кодом без передплати, оплата за фактом користування.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'РОЗПОЧАТИ КОРИСТУВАННЯ ЗА $smallAmount';
  }

  @override
  String get importAccount => 'ІМПОРТ РАХУНКУ';

  @override
  String get illDoThisLater => 'Пізніше';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Поповніть спільний рахунок Orchid, придбавши кредити VPN, щоб автоматично підключатися до <link1>рекомендованих провайдерів</link1>.';

  @override
  String get confirmPurchase => 'ПІДТВЕРДИТИ ПОКУПКУ';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'Для рахунків Orchid використовуються кредити VPN, забезпечені <link>криптовалютою xDAI</link>. Рахунки передбачають цілодобову підтримку клієнтів, необмежений доступ до пристроїв та повернення коштів із магазину додатків згідно з його правилами.';

  @override
  String get yourPurchaseIsInProgress => 'Покупка оброблюється.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'Обробка цієї покупки займає більше часу, ніж очікувалося. Імовірно, виникла помилка.';

  @override
  String get thisMayTakeAMinute => 'Це займе деякий час...';

  @override
  String get vpnCredits => 'Кредити VPN';

  @override
  String get blockchainFee => 'Комісія блокчейну';

  @override
  String get promotion => 'Знижка';

  @override
  String get showInAccountManager => 'Показувати в диспетчері рахунків';

  @override
  String get deleteThisOrchidIdentity => 'Видалити цей ідентифікатор Orchid';

  @override
  String get chooseIdentity => 'Вибрати ідентифікатор';

  @override
  String get updatingAccounts => 'Оновлення рахунків';

  @override
  String get trafficAnalysis => 'Аналіз трафіку';

  @override
  String get accountManager => 'Диспетчер рахунків';

  @override
  String get circuitBuilder => 'Конструктор ланцюжків';

  @override
  String get exitHop => 'Стрибок виходу';

  @override
  String get entryHop => 'Стрибок входу';

  @override
  String get addNewHop => 'ДОДАТИ НОВИЙ СТРИБОК';

  @override
  String get newCircuitBuilder => 'Новий конструктор ланцюжків!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Тепер ви можете заплатити в xDAI за ланцюжок Orchid із кількома стрибками. Багатострибковий інтерфейс одночасно з конфігураціями OpenVPN і WireGuard зараз підтримує рахунки xDAI та OXT Orchid, що можна об’єднати в цибулевий маршрут.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Керуйте з’єднанням за допомогою конструктора ланцюжків замість диспетчера рахунків. Усі з’єднання тепер використовують ланцюжок із нульовим стрибком або кількома стрибками. Наявні конфігурації перенесено до конструктора ланцюжків.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Швидкий старт за $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Ми додали новий спосіб придбати рахунок Orchid і створити однострибковий ланцюжок з головного екрана, щоб швидше розпочати користування.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid — унікальний клієнт цибулевої або багатострибкової маршрутизації, що підтримує кілька протоколів VPN. Можна налаштувати з’єднання, об’єднавши стрибки з підтримуваних протоколів, зазначених нижче.\n\nОдин стрибок схожий на звичайний VPN. Три стрибка (для досвідчених користувачів) — це класичний варіант цибулевої маршрутизації. Нульові стрибки дозволяють аналізувати трафік без використання VPN-тунелю.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'Видалення стрибків OpenVPN та Wireguard призведе до втрати пов’язаних облікових даних та конфігурації підключення. Обов’язково створіть резервну копію даних перед продовженням.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Видалення не може бути скасовано. Щоб зберегти цей ідентифікатор, натисніть «Скасувати» та скористайтеся параметром «Експорт»';

  @override
  String get unlockTime => 'Час розблокування';

  @override
  String get chooseChain => 'Вибрати блокчейн';

  @override
  String get unlocking => 'Розблокується';

  @override
  String get unlocked => 'Розблоковано';

  @override
  String get orchidTransaction => 'Транзакція Orchid';

  @override
  String get confirmations => 'Підтвердження';

  @override
  String get pending => 'Очікування...';

  @override
  String get txHash => 'Хеш транзакції:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Усі кошти доступні для зняття.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return 'Доступно для зняття $maxWithdraw з $totalFunds загальних коштів.';
  }

  @override
  String get alsoUnlockRemainingDeposit =>
      'Також розблокувати залишок депозиту';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Якщо ви зазначите не повну суму, кошти стягуватимуться спочатку з вашого балансу.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Дивіться додаткові параметри на панелі РОЗШИРЕНІ.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Якщо ви виберете параметр розблокування депозиту, внаслідок транзакції буде негайно знято з балансу зазначену суму, а також розпочнеться процес розблокування решти депозиту.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Кошти можна зняти з депозиту через 24 години після розблокування.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Знімайте кошти з рахунка Orchid на поточний гаманець.';

  @override
  String get withdrawAndUnlockFunds => 'ЗНЯТТЯ Й РОЗБЛОКУВАННЯ КОШТІВ';

  @override
  String get withdrawFunds => 'ЗНЯТТЯ КОШТІВ';

  @override
  String get withdrawFunds2 => 'вивести кошти';

  @override
  String get withdraw => 'Зняти';

  @override
  String get submitTransaction => 'НАДІСЛАТИ ТРАНЗАКЦІЮ';

  @override
  String get move => 'Переказати';

  @override
  String get now => 'Зараз';

  @override
  String get amount => 'Сума';

  @override
  String get available => 'Доступно';

  @override
  String get select => 'Вибрати';

  @override
  String get add => 'ДОДАТИ';

  @override
  String get balanceToDeposit => 'З БАЛАНСУ НА ДЕПОЗИТ';

  @override
  String get depositToBalance => 'З ДЕПОЗИТУ НА БАЛАНС';

  @override
  String get setWarnedAmount => 'Задати резервовану суму';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Додати кошти до балансу і/або депозиту рахунку Orchid.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Читайте на сайті <link>orchid.com</link> рекомендації з розподілення сум на рахункові';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Поточна попередня авторизація $tokenType: $amount';
  }

  @override
  String get noWallet => 'Немає гаманця';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Не зазначено гаманець або не підтримується браузер.';

  @override
  String get error => 'Помилка';

  @override
  String get failedToConnectToWalletconnect =>
      'Не вдалося підключитися до WalletConnect.';

  @override
  String get unknownChain => 'Невідомий блокчейн';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'Диспетчер рахунків Orchid наразі не підтримує цей блокчейн.';

  @override
  String get orchidIsntOnThisChain => 'Orchid не працює з цим блокчейном.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'Контракт Orchid ще не розгорнуто в цьому блокчейні.';

  @override
  String get moveFunds => 'ПЕРЕКАЗАТИ КОШТИ';

  @override
  String get moveFunds2 => 'Переміщення коштів';

  @override
  String get lockUnlock => 'БЛОКУВАТИ / РОЗБЛОКУВАТИ';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'Депозит $amount розблоковано.';
  }

  @override
  String get locked => 'заблоковано';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'Депозит $amount $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'Кошти можна зняти через $time.';
  }

  @override
  String get lockDeposit => 'БЛОКУВАТИ ДЕПОЗИТ';

  @override
  String get unlockDeposit => 'РОЗБЛОКУВАТИ ДЕПОЗИТ';

  @override
  String get advanced => 'РОЗШИРЕНІ';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Докладніше про рахунки Orchid</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Приблизна вартість створення рахунку Orchid з ефективністю $efficiency та $num квитка(-ів) вартості.';
  }

  @override
  String get chain => 'Блокчейн';

  @override
  String get token => 'Токен';

  @override
  String get minDeposit => 'Мін. депозит';

  @override
  String get minBalance => 'Мін. баланс';

  @override
  String get fundFee => 'Комісія за поповнення';

  @override
  String get withdrawFee => 'Комісія за зняття';

  @override
  String get tokenValues => 'ВАРТІСТЬ ТОКЕНІВ';

  @override
  String get usdPrices => 'ЦІНИ В USD';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'Для зняття коштів через 24 години, зазначте суму резервованого депозиту.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'Протягом цього часу кошти залишатимуться недоступними для депонування в мережі Orchid.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Кошти можна повторно заблокувати в будь-який момент, зменшивши резервовану суму.';

  @override
  String get warn => 'Резервувати';

  @override
  String get totalWarnedAmount => 'Загальна резервована сума';

  @override
  String get newIdentity => 'Новий ідентифікатор';

  @override
  String get importIdentity => 'Імпортувати ідентифікатор';

  @override
  String get exportIdentity => 'Експортувати ідентифікатор';

  @override
  String get deleteIdentity => 'Видалити ідентифікатор';

  @override
  String get importOrchidIdentity => 'Імпортувати ідентифікатор Orchid';

  @override
  String get funderAddress => 'Фінансувальна адреса';

  @override
  String get contract => 'Контракт';

  @override
  String get txFee => 'Комісія за транзакцію';

  @override
  String get show => 'Показувати';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Помилки';

  @override
  String get lastHour => 'За останню годину';

  @override
  String get chainSettings => 'Налаштування блокчейну';

  @override
  String get price => 'Ціна';

  @override
  String get failed => 'Збій';

  @override
  String get fetchGasPrice => 'Ціна газу';

  @override
  String get fetchLotteryPot => 'Спільний фонд';

  @override
  String get lines => 'рядки';

  @override
  String get filtered => 'відфільтровано';

  @override
  String get backUpYourIdentity => 'Створіть резервну копію своєї особи';

  @override
  String get accountSetUp => 'Налаштування облікового запису';

  @override
  String get setUpAccount => 'Налаштувати обліковий запис';

  @override
  String get generateIdentity => 'ГЕНЕРУЙТЕ ІДЕНТИЧНІСТЬ';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Введіть наявну <account_link>ідентифікацію орхідеї</account_link>';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Вставте нижче адресу гаманця web3, яку ви використовуватимете для поповнення свого облікового запису.';

  @override
  String get funderWalletAddress => 'Адреса гаманця спонсора';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Ваша публічна адреса Orchid Identity';

  @override
  String get continueButton => 'продовжити';

  @override
  String get yesIHaveSavedACopyOf =>
      'Так, я зберіг копію свого приватного ключа в надійному місці.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Створіть резервну копію свого <bold>закритого ключа</bold>Orchid Identity. Вам знадобиться цей ключ, щоб поділитися, імпортувати або відновити цю особу та всі пов’язані облікові записи.';

  @override
  String get locked1 => 'заблокований';

  @override
  String get unlockDeposit1 => 'Розблокувати депозит';

  @override
  String get changeWarnedAmountTo => 'Змінити попереджену суму на';

  @override
  String get setWarnedAmountTo => 'Установити попереджену суму';

  @override
  String get currentWarnedAmount => 'Поточна попереджена сума';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Усі попереджені кошти будуть заблоковані до';

  @override
  String get balanceToDeposit1 => 'Залишок до депозиту';

  @override
  String get depositToBalance1 => 'Депозит на баланс';

  @override
  String get advanced1 => 'Додатково';

  @override
  String get add1 => 'Додати';

  @override
  String get lockUnlock1 => 'Блокування / Розблокування';

  @override
  String get viewLogs => 'Переглянути журнали';

  @override
  String get language => 'Мова';

  @override
  String get systemDefault => 'За замовчуванням система';

  @override
  String get identiconStyle => 'Стиль ідентифікатора';

  @override
  String get blockies => 'Блоки';

  @override
  String get jazzicon => 'Джазикон';

  @override
  String get contractVersion => 'Контрактна версія';

  @override
  String get version0 => 'Версія 0';

  @override
  String get version1 => 'Версія 1';

  @override
  String get connectedWithMetamask => 'Підключено до Metamask';

  @override
  String get blockExplorer => 'Провідник блоків';

  @override
  String get tapToMinimize => 'Торкніться, щоб згорнути';

  @override
  String get connectWallet => 'ПІДКЛЮЧИТИ ГАМАНЕЦЬ';

  @override
  String get checkWallet => 'Перевірте гаманець';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Перевірте програму або розширення Wallet на наявність запиту, що очікує на розгляд.';

  @override
  String get test => 'тест';

  @override
  String get chainName => 'Назва ланцюга';

  @override
  String get rpcUrl => 'URL-адреса RPC';

  @override
  String get tokenPrice => 'Ціна токена';

  @override
  String get tokenPriceUsd => 'Ціна токена в доларах США';

  @override
  String get addChain => 'Додати ланцюжок';

  @override
  String get deleteChainQuestion => 'Видалити ланцюжок?';

  @override
  String get deleteUserConfiguredChain =>
      'Видалити налаштований користувачем ланцюжок';

  @override
  String get fundContractDeployer => 'Розпорядник контракту фонду';

  @override
  String get deploySingletonFactory => 'Розгорніть Singleton Factory';

  @override
  String get deployContract => 'Контракт розгортання';

  @override
  String get about => 'Про';

  @override
  String get dappVersion => 'Версія Dapp';

  @override
  String get viewContractOnEtherscan => 'Переглянути контракт на Etherscan';

  @override
  String get viewContractOnGithub => 'Переглянути договір на Github';

  @override
  String get accountChanges => 'Зміни облікового запису';

  @override
  String get name => 'ім\'я';

  @override
  String get step1 =>
      '<bold>Крок 1.</bold> Підключіть гаманець ERC-20 із <link>достатньою кількістю токенів</link> у ньому.';

  @override
  String get step2 =>
      '<bold>Крок 2.</bold> Скопіюйте Orchid Identity із програми Orchid, перейшовши до «Керування обліковими записами» та торкнувшись адреси.';

  @override
  String get connectOrCreate =>
      'Підключіть або створіть обліковий запис Orchid';

  @override
  String get lockDeposit2 => 'Замок депозиту';

  @override
  String get unlockDeposit2 => 'Розблокувати депозит';

  @override
  String get enterYourWeb3 => 'Введіть адресу свого гаманця web3.';

  @override
  String get purchaseComplete => 'Покупку завершено';

  @override
  String get generateNewIdentity => 'Створіть нову ідентифікацію';

  @override
  String get copyIdentity => 'Копіювати ідентифікатор';

  @override
  String get yourPurchaseIsComplete =>
      'Вашу покупку завершено та зараз обробляється блокчейном xDai, що може зайняти кілька хвилин. За допомогою цього облікового запису для вас було створено стандартну схему. Ви можете контролювати доступний баланс на головному екрані або в менеджері облікового запису.';

  @override
  String get circuitGenerated => 'Згенерована схема';

  @override
  String get usingYourOrchidAccount =>
      'Використовуючи ваш обліковий запис Orchid, було згенеровано один стрибок. Ви можете керувати цим з екрана конструктора схем.';
}
