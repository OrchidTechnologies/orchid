// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get orchidHop => 'Orchid скачок';

  @override
  String get orchidDisabled => 'Служба Orchid отключена';

  @override
  String get trafficMonitoringOnly => 'Только мониторинг трафика';

  @override
  String get orchidConnecting => 'Orchid подключается';

  @override
  String get orchidDisconnecting => 'Orchid отключается';

  @override
  String numHopsConfigured(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num подключения настроено',
      two: 'Два подключения настроено',
      one: 'Одно подключение настроено',
      zero: 'Подключения не настроены',
      many: '$num подключений настроено',
      few: '$num подключения настроено',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Удалить';

  @override
  String get orchid => 'Orchid';

  @override
  String get openVPN => 'OpenVPN';

  @override
  String get hops => 'Скачки';

  @override
  String get traffic => 'Трафик';

  @override
  String get curation => 'Курирование';

  @override
  String get signerKey => 'Ключ подписанта';

  @override
  String get copy => 'Копировать';

  @override
  String get paste => 'Вставить';

  @override
  String get deposit => 'Депозит';

  @override
  String get curator => 'Куратор';

  @override
  String get ok => 'ОК';

  @override
  String get settingsButtonTitle => 'НАСТРОЙКИ';

  @override
  String get confirmThisAction => 'Подтвердите это действие';

  @override
  String get cancelButtonTitle => 'ОТМЕНА';

  @override
  String get changesWillTakeEffectInstruction =>
      'Изменения вступят в силу после перезапуска VPN.';

  @override
  String get saved => 'Сохранено';

  @override
  String get configurationSaved => 'Конфигурация сохранена';

  @override
  String get whoops => 'Ошибочка';

  @override
  String get configurationFailedInstruction =>
      'Не удалось сохранить конфигурацию. Проверьте синтаксис и попробуйте еще раз.';

  @override
  String get addHop => 'Добавить скачок';

  @override
  String get scan => 'Сканировать';

  @override
  String get invalidQRCode => 'Неверный QR-код';

  @override
  String get theQRCodeYouScannedDoesNot =>
      'Отсканированный код не содержит действующей конфигурации счета.';

  @override
  String get invalidCode => 'Неверный код';

  @override
  String get theCodeYouPastedDoesNot =>
      'Вставленный код не содержит действующей конфигурации счета.';

  @override
  String get openVPNHop => 'OpenVPN скачок';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get config => 'Конфигурация';

  @override
  String get pasteYourOVPN => 'Вставьте сюда свой файл конфигурации OVPN';

  @override
  String get enterYourCredentials => 'Введите свои учетные данные';

  @override
  String get enterLoginInformationInstruction =>
      'Введите логин информацию для своего VPN-провайдера выше. Затем вставьте содержимое файла конфигурации OpenVPN провайдера в соответствующее поле.';

  @override
  String get save => 'Сохранить';

  @override
  String get help => 'Справка';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get openSourceLicenses => 'Лицензии с открытым исходным кодом';

  @override
  String get settings => 'Настройки';

  @override
  String get version => 'Версия';

  @override
  String get noVersion => 'Нет версии';

  @override
  String get orchidOverview => 'Обзор Orchid';

  @override
  String get defaultCurator => 'Стандартный куратор';

  @override
  String get queryBalances => 'Баланс запросов';

  @override
  String get reset => 'Сбросить';

  @override
  String get manageConfiguration => 'Управление конфигурацией';

  @override
  String get warningThesefeature =>
      'Предупреждение: эти функции предназначены только для опытных пользователей. Пожалуйста, прочитайте все инструкции.';

  @override
  String get exportHopsConfiguration => 'Экспорт конфигурации подключения';

  @override
  String get export => 'Экспорт';

  @override
  String get warningExportedConfiguration =>
      'Предупреждение: экспортированная конфигурация включает секретные закрытые ключи подписанта для экспортируемых скачков. Раскрывая закрытие ключи, вы можете потерять все средства на соответствующих счетах Orchid.';

  @override
  String get importHopsConfiguration => 'Импорт конфигурации скачков';

  @override
  String get import => 'Импорт';

  @override
  String get warningImportedConfiguration =>
      'Предупреждение: импортированная конфигурация заменит любые существующие подключения, созданные в приложении. Ключи подписанта, ранее сгенерированные или импортированные на этом устройстве, сохранятся и останутся доступными для создания новых скачков, однако все остальные настройки, включая настройки подключения OpenVPN, будут потеряны.';

  @override
  String get configuration => 'Конфигурация';

  @override
  String get saveButtonTitle => 'СОХРАНИТЬ';

  @override
  String get search => 'Поиск';

  @override
  String get newContent => 'Новый контент';

  @override
  String get clear => 'Очистить';

  @override
  String get connectionDetail => 'Сведения о подключении';

  @override
  String get host => 'Хост';

  @override
  String get time => 'Время';

  @override
  String get sourcePort => 'Порт источника';

  @override
  String get destination => 'Назначение';

  @override
  String get destinationPort => 'Порт назначения';

  @override
  String get generateNewKey => 'Сгенерировать новый ключ';

  @override
  String get importKey => 'Импортировать ключ';

  @override
  String get nothingToDisplayYet =>
      'Пока нет данных. Трафик появится здесь, когда будет что показать.';

  @override
  String get disconnecting => 'Отключение...';

  @override
  String get connecting => 'Подключение ...';

  @override
  String get pushToConnect => 'Нажмите, чтобы подключиться.';

  @override
  String get orchidIsRunning => 'Orchid работает!';

  @override
  String get pacPurchaseWaiting => 'Ожидание покупки';

  @override
  String get retry => 'Повторить';

  @override
  String get getHelpResolvingIssue =>
      'Получить помощь в решении этой проблемы.';

  @override
  String get copyDebugInfo => 'Копировать отладочную информацию';

  @override
  String get contactOrchid => 'Связаться c Orchid';

  @override
  String get remove => 'Удалить';

  @override
  String get deleteTransaction => 'Удалить транзакцию';

  @override
  String get clearThisInProgressTransactionExplain =>
      'Очистите эту незавершенную транзакцию. Это не возместит вашу покупку в приложении. Вы должны связаться с Orchid, чтобы решить эту проблему.';

  @override
  String get preparingPurchase => 'Подготовка покупки';

  @override
  String get retryingPurchasedPAC => 'Повторная попытка покупки';

  @override
  String get retryPurchasedPAC => 'Повторить попытку покупки';

  @override
  String get purchaseError => 'Ошибка покупки';

  @override
  String get thereWasAnErrorInPurchasingContact =>
      'Произошла ошибка при покупке. Пожалуйста, свяжитесь со службой поддержки Orchid.';

  @override
  String get importAnOrchidAccount => 'Импортировать учетную запись Orchid';

  @override
  String get buyCredits => 'Купить кредиты';

  @override
  String get linkAnOrchidAccount => 'Связать аккаунт Orchid';

  @override
  String get weAreSorryButThisPurchaseWouldExceedTheDaily =>
      'К сожалению, эта покупка превышает лимит кредитов доступа за день. Попробуйте позже.';

  @override
  String get marketStats => 'Статистика рынка';

  @override
  String get balanceTooLow => 'Слишком низкий баланс';

  @override
  String get depositSizeTooSmall => 'Слишком маленький размер депозита';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourBalance =>
      'Ваша максимальная стоимость билета в настоящее время ограничена вашим балансом';

  @override
  String get yourMaxTicketValueIsCurrentlyLimitedByYourDeposit =>
      'Ваша максимальная стоимость билета в настоящее время ограничена вашим депозитом';

  @override
  String get considerAddingOxtToYourAccountBalance =>
      'Подумайте о добавлении OXT на баланс вашего аккаунта.';

  @override
  String get considerAddingOxtToYourDepositOrMovingFundsFrom =>
      'Попробуйте добавить OXT на свой депозит или переведите средства с баланса на ваш депозит.';

  @override
  String get prices => 'Цены';

  @override
  String get ticketValue => 'Стоимость билета';

  @override
  String get costToRedeem => 'Стоимость выкупа:';

  @override
  String get viewTheDocsForHelpOnThisIssue =>
      'Посмотреть документы для помощи по этому вопросу.';

  @override
  String get goodForBrowsingAndLightActivity =>
      'Хорошо подходит для браузинга и легкой активности';

  @override
  String get learnMore => 'Узнать больше.';

  @override
  String get connect => 'Будем на связи';

  @override
  String get disconnect => 'Отключить';

  @override
  String get wireguardHop => 'WireGuard Скачок';

  @override
  String get pasteYourWireguardConfigFileHere =>
      'Вставьте свой файл конфигурации WireGuard здесь';

  @override
  String get pasteTheCredentialInformationForYourWireguardProviderIntoThe =>
      'Вставьте учетные данные для вашего провайдера WireGuard в поле выше.';

  @override
  String get wireguard => 'WireGuard';

  @override
  String get clearAllLogData => 'Очистить все данные журнала?';

  @override
  String get thisDebugLogIsNonpersistentAndClearedWhenQuittingThe =>
      'Этот журнал отладки непостоянен и очищается при выходе из приложения.';

  @override
  String get itMayContainSecretOrPersonallyIdentifyingInformation =>
      'Может содержать секретную или личную информацию.';

  @override
  String get loggingEnabled => 'Ведение журнала включено';

  @override
  String get cancel => 'ОТМЕНА';

  @override
  String get logging => 'протоколирование';

  @override
  String get loading => 'Загрузка ...';

  @override
  String get ethPrice => 'ETH цена:';

  @override
  String get oxtPrice => 'Цена OXT:';

  @override
  String get gasPrice => 'Цена на газ:';

  @override
  String get maxFaceValue => 'Макс номинал:';

  @override
  String get confirmDelete => 'Подтвердите удаление';

  @override
  String get enterOpenvpnConfig => 'ввести OpenVPN конфигурацию ';

  @override
  String get enterWireguardConfig => 'ввести  WireGuard®️ конфигурацию';

  @override
  String get starting => 'запуск...';

  @override
  String get legal => 'Правовая информация';

  @override
  String get whatsNewInOrchid => 'Что нового в Orchid';

  @override
  String get orchidIsOnXdai => 'Orchid на xDai!';

  @override
  String get youCanNowPurchaseOrchidCreditsOnXdaiStartUsing =>
      'Теперь кредиты Orchid можно приобретать на xDai! Пользуйтесь VPN по цене от 1 долл. США.';

  @override
  String get xdaiAccountsForPastPurchases =>
      'На xDai учитываются прошлые покупки';

  @override
  String get forAnyInappPurchaseMadeBeforeTodayXdaiFundsHave =>
      'За каждую покупку в приложении, которую вы сделали до сегодняшнего дня, на тот же ключ аккаунта начисляются средства в xDai. Пользуйтесь VPN за наш счет!';

  @override
  String get newInterface => 'Новый интерфейс';

  @override
  String get accountsAreNowOrganizedUnderTheOrchidAddressTheyAre =>
      'Теперь аккаунты упорядочиваются по адресу Orchid, с которым они связаны.';

  @override
  String get seeYourActiveAccountBalanceAndBandwidthCostOnThe =>
      'Просматривайте текущий баланс на счете и стоимость пользования VPN на домашней странице.';

  @override
  String get seeOrchidcomForHelp => 'Подробнее на orchid.com.';

  @override
  String get payPerUseVpnService => 'VPN с платой по факту использования';

  @override
  String get notASubscriptionCreditsDontExpire =>
      'Это не подписка — ваши кредиты не сгорают';

  @override
  String get shareAccountWithUnlimitedDevices =>
      'Пользуйтесь аккаунтом с неограниченного количества устройств';

  @override
  String get theOrchidStoreIsTemporarilyUnavailablePleaseCheckBackIn =>
      'Магазин Orchid Store временно недоступен. Попробуйте зайти через пару минут.';

  @override
  String get talkingToPacServer => 'Подключаемся к серверу аккаунтов Orchid';

  @override
  String get advancedConfiguration => 'Продвинутая конфигурация';

  @override
  String get newWord => 'Новое';

  @override
  String get copied => 'Скопировано';

  @override
  String get efficiency => 'Эффективность';

  @override
  String minTicketsAvailableTickets(int tickets) {
    return 'Мин. заявки доступны: $tickets';
  }

  @override
  String get transactionSentToBlockchain => 'Транзакция отправлена в блокчейн';

  @override
  String get yourPurchaseIsCompleteAndIsNowBeingProcessedBy =>
      'Ваша покупка завершена, сейчас она обрабатывается блокчейном xDai. Это занимает примерно минуту, иногда немного дольше. Потяните экран вниз, чтобы обновить, и информация об обновлении баланса в вашем аккаунте появится ниже.';

  @override
  String get copyReceipt => 'Копировать квитанцию';

  @override
  String get manageAccounts => 'Управление аккаунтами';

  @override
  String get configurationManagement => 'Управление конфигурацией';

  @override
  String get exportThisOrchidKey => 'Экспортировать этот ключ Orchid';

  @override
  String get aQrCodeAndTextForAllTheOrchidAccounts =>
      'QR-код и текст для всех аккаунтов Orchid, связанных с этим ключом, приводится ниже.';

  @override
  String get importThisKeyOnAnotherDeviceToShareAllThe =>
      'Импортируйте этот ключ на другое устройство, чтобы поделиться с ним всеми аккаунтами Orchid, связанными с этим профилем Orchid.';

  @override
  String get orchidAccountInUse => 'Аккаунт Orchid используется';

  @override
  String get thisOrchidAccountIsInUseAndCannotBeDeleted =>
      'Этот аккаунт Orchid используется и не может быть удален.';

  @override
  String get pullToRefresh => 'Потяните, чтобы обновить.';

  @override
  String get balance => 'Баланс';

  @override
  String get active => 'Активный';

  @override
  String get pasteAnOrchidKeyFromTheClipboardToImportAll =>
      'Вставьте ключ Orchid из буфера обмена, чтобы импортировать все связанные с ним аккаунты Orchid.';

  @override
  String get scanOrPasteAnOrchidKeyFromTheClipboardTo =>
      'Отсканируйте или вставьте ключ Orchid из буфера обмена, чтобы импортировать все связанные с ним аккаунты Orchid.';

  @override
  String get account => 'Счет';

  @override
  String get transactions => 'Транзакции';

  @override
  String get weRecommendBackingItUp =>
      'Рекомендуем <link>создать его резервную копию</link>.';

  @override
  String get copiedOrchidIdentity => 'Скопирован идентификатор Orchid';

  @override
  String get thisIsNotAWalletAddress => 'Это не адрес кошелька.';

  @override
  String get doNotSendTokensToThisAddress =>
      'Не отправляйте токены на этот адрес.';

  @override
  String get yourOrchidIdentityUniquelyIdentifiesYouOnTheNetwork =>
      'Идентификатор Orchid уникален для вас в сети.';

  @override
  String get learnMoreAboutYourLinkorchidIdentitylink =>
      'Подробнее о вашем <link>идентификаторе Orchid</link>.';

  @override
  String get analyzingYourConnections => 'Ваши подключения анализируются';

  @override
  String get analyzeYourConnections => 'Проанализировать ваши подключения';

  @override
  String get networkAnalysisUsesYourDevicesVpnFacilityToCapturePackets =>
      'Функция анализа сети использует функционал VPN на вашем устройстве, чтобы улавливать пакеты данных и анализировать трафик.';

  @override
  String get networkAnalysisRequiresVpnPermissionsButDoesNotByItself =>
      'Функция анализа сети требует доступа к VPN, но сама по себе не защищает ваши данные и не скрывает ваш IP-адрес.';

  @override
  String get toGetTheBenefitsOfNetworkPrivacyYouMustConfigure =>
      'Чтобы пользоваться преимуществами приватного доступа к сети, настройте и активируйте VPN-подключение на домашней странице.';

  @override
  String get turningOnThisFeatureWillIncreaseTheBatteryUsageOf =>
      'Включение данной функции приведет к большему расходу заряда аккумулятора приложением Orchid.';

  @override
  String get useAnOrchidAccount => 'Использовать аккаунт Orchid';

  @override
  String get pasteAddress => 'Вставьте адрес';

  @override
  String get chooseAddress => 'Выберите адрес';

  @override
  String get chooseAnOrchidAccountToUseWithThisHop =>
      'Выберите аккаунт Orchid для этого подключения.';

  @override
  String get ifYouDontSeeYourAccountBelowYouCanUse =>
      'Если ниже вы не видите свой аккаунт, вы можете воспользоваться менеджером аккаунтов, чтобы импортировать, купить или создать новый.';

  @override
  String get selectAnOrchidAccount => 'Выберите аккаунт Orchid';

  @override
  String get takeMeToTheAccountManager => 'Перейти в менеджер аккаунтов';

  @override
  String get funderAccount => 'Спонсорский счет';

  @override
  String get orchidRunningAndAnalyzing => 'Orchid работает и выполняет анализ';

  @override
  String get startingVpn => '(Запускается VPN)';

  @override
  String get disconnectingVpn => '(Отключение от VPN)';

  @override
  String get orchidAnalyzingTraffic => 'Orchid анализирует трафик';

  @override
  String get vpnConnectedButNotRouting =>
      '(VPN-соединение установлено, но без маршрутизации)';

  @override
  String get restarting => 'Перезапуск';

  @override
  String get changingMonitoringStatusRequiresRestartingTheVpnWhichMayBriefly =>
      'Для изменения статуса мониторинга нужно перезапустить VPN. Это может на короткое время оставить вас без защиты конфиденциальности.';

  @override
  String get confirmRestart => 'Подтверждение перезапуска';

  @override
  String averagePriceIsUSDPerGb(String price) {
    return 'Средняя цена составляет $price долл. США за ГБ';
  }

  @override
  String get myOrchidConfig => 'Моя конфигурация Orchid';

  @override
  String get noAccountSelected => 'Аккаунт не выбран';

  @override
  String get inactive => 'Неактивно';

  @override
  String get tickets => 'Заявки';

  @override
  String get accounts => 'Аккаунты';

  @override
  String get orchidIdentity => 'Идентификатор Orchid';

  @override
  String get addFunds => 'ПОПОЛНИТЬ СЧЕТ';

  @override
  String get addFunds2 => 'Добавить средства';

  @override
  String get gb => 'ГБ';

  @override
  String get usdgb => 'ДОЛЛ/ГБ';

  @override
  String get hop => 'Подключение';

  @override
  String get circuit => 'Цепь';

  @override
  String get clearAllAnalysisData => 'Очистить все данные анализа?';

  @override
  String get thisActionWillClearAllPreviouslyAnalyzedTrafficConnectionData =>
      'Это действие очистит все данные о трафике соединения проанализированном ранее.';

  @override
  String get clearAll => 'ОЧИСТИТЬ ВСЕ';

  @override
  String get stopAnalysis => 'ПРЕРВАТЬ АНАЛИЗ';

  @override
  String get startAnalysis => 'НАЧАТЬ АНАЛИЗ';

  @override
  String get orchidAccountsInclude247CustomerSupportUnlimitedDevicesAndAre =>
      'Аккаунты Orchid — это круглосуточная служба поддержки без выходных и неограниченное количество устройств. Они работают на базе <link2>криптовалюты xDai</link2>.';

  @override
  String get purchasedAccountsConnectExclusivelyToOur =>
      'Приобретенные аккаунты подключаются исключительно к <link1>нашим избранным провайдерам</link1>.';

  @override
  String get refundPolicyCoveredByAppStores =>
      'Политика возврата средств определяется магазинами приложений.';

  @override
  String get orchidIsUnableToDisplayInappPurchasesAtThisTime =>
      'В настоящее время Orchid не может отображать покупки в приложении.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredFor =>
      'Убедитесь, что это устройство поддерживает покупки в приложении и настроено для них.';

  @override
  String get pleaseConfirmThatThisDeviceSupportsAndIsConfiguredForOrUseOurDecentralized =>
      'Убедитесь, что это устройство поддерживает покупки в приложении и настроено для них. Вы также можете воспользоваться нашей децентрализованной системой <link>управления аккаунтами</link>.';

  @override
  String get buy => 'КУПИТЬ';

  @override
  String get gbApproximately12 => '12 ГБ (приблизительно)';

  @override
  String get gbApproximately60 => '60 ГБ (приблизительно)';

  @override
  String get gbApproximately240 => '240 ГБ (приблизительно)';

  @override
  String get idealSizeForMediumtermIndividualUsageThatIncludesBrowsingAnd =>
      'Подходит для среднесрочного индивидуального использования с просмотром сайтов и нересурсоемкими трансляциями.';

  @override
  String get mostPopular => 'Хит продаж!';

  @override
  String get bandwidthheavyLongtermUsageOrSharedAccounts =>
      'Задействована большая часть пропускной способности, долгосрочное использование или многопользовательский доступ к аккаунтам.';

  @override
  String get total => 'Всего';

  @override
  String get pausingAllTraffic => 'Приостанавливаем весь трафик...';

  @override
  String get queryingEthereumForARandom =>
      'Запрашиваем случайного провайдера в Ethereum...';

  @override
  String get quickFundAnAccount => 'Быстрое пополнение счета!';

  @override
  String get accountFound => 'Учетная запись найдена';

  @override
  String get weFoundAnAccountAssociatedWithYourIdentitiesAndCreated =>
      'Мы нашли учетную запись, связанную с вашими данными, и создали цепь Orchid с одним подключением. VPN-сеть готова к использованию.';

  @override
  String get welcomeToOrchid => 'Добро пожаловать в Orchid!';

  @override
  String get fundYourAccount => 'Пополните счет';

  @override
  String get processing => 'Идет обработка…';

  @override
  String get subscriptionfreePayAsYouGoDecentralizedOpenSourceVpnService =>
      'Децентрализованный VPN-сервис с открытым кодом, без платы за подписку, оплата за использование.';

  @override
  String getStartedFor1(String smallAmount) {
    return 'НАЧАТЬ РАБОТУ ЗА $smallAmount';
  }

  @override
  String get importAccount => 'ИМПОРТ УЧЕТНОЙ ЗАПИСИ';

  @override
  String get illDoThisLater => 'Не сейчас';

  @override
  String get connectAutomaticallyToOneOfTheNetworksLink1preferredProviderslink1By =>
      'Приобретите VPN-кредиты, чтобы пополнить счет учетной записи Orchid (вы сможете пополнять ее повторно, а также пользоваться ей вместе с другими пользователями). После этого вы автоматически подключитесь к одному из <link1>избранных провайдеров</link1> нашей сети.';

  @override
  String get confirmPurchase => 'ПОДТВЕРДИТЬ ПОКУПКУ';

  @override
  String get orchidAccountsUseVpnCreditsBackedByTheLinkxdaiCryptocurrencylink =>
      'В учетных записях Orchid используются VPN-кредиты, обеспеченные <link>криптовалютой xDAI</link>. Действует круглосуточная служба поддержки клиентов, распространяется политика возврата средств магазином приложений, а учетную запись можно использовать на любом количестве устройств.';

  @override
  String get yourPurchaseIsInProgress => 'Ваша покупка в обработке.';

  @override
  String get thisPurchaseIsTakingLongerThanExpectedToProcessAnd =>
      'Покупка обрабатывается дольше положенного. Возможно, произошла ошибка.';

  @override
  String get thisMayTakeAMinute => 'Это может занять примерно минуту…';

  @override
  String get vpnCredits => 'VPN-кредиты';

  @override
  String get blockchainFee => 'Комиссия блокчейна';

  @override
  String get promotion => 'Промо';

  @override
  String get showInAccountManager => 'Показать в менеджере учетных записей';

  @override
  String get deleteThisOrchidIdentity => 'Удалить этот идентификатор Orchid';

  @override
  String get chooseIdentity => 'Выбрать идентификатор';

  @override
  String get updatingAccounts => 'Идет обновление учетных записей';

  @override
  String get trafficAnalysis => 'Анализ трафика';

  @override
  String get accountManager => 'Менеджер учетных записей';

  @override
  String get circuitBuilder => 'Конструктор цепи';

  @override
  String get exitHop => 'Выходное подключение';

  @override
  String get entryHop => 'Входное подключение';

  @override
  String get addNewHop => 'ДОБАВИТЬ ПОДКЛЮЧЕНИЕ';

  @override
  String get newCircuitBuilder => 'Новый конструктор цепи!';

  @override
  String get youCanNowPayForAMultihopOrchidCircuitWith =>
      'Теперь оплатить цепь Orchid с несколькими подключениями можно с помощью xDai. Интерфейс множества подключений поддерживает учетные записи Orchid на xDai и OXT, а также по-прежнему поддерживает конфигурации OpenVPN и WireGuard, которые можно объединять в «луковую» маршрутизацию.';

  @override
  String get manageYourConnectionFromTheCircuitBuilderInsteadOfThe =>
      'Управляйте соединением через конструктор цепи вместо менеджера учетных записей. Во всех соединениях теперь используется цепь с 0 или более подключениями. Если у вас уже была конфигурация, она перенесена в конструктор цепи.';

  @override
  String quickStartFor1(String smallAmount) {
    return 'Быстрый старт за $smallAmount';
  }

  @override
  String get weAddedAMethodToPurchaseAnOrchidAccountAnd =>
      'Мы добавили возможность купить учетную запись Orchid и создать цепь с одним подключением прямо с главного экрана, чтобы вы могли быстрее начать работу.';

  @override
  String get orchidIsUniqueAsAMultiHopOrOnion =>
      'Orchid — уникальный клиент для нескольких подключений и «луковой» маршрутизации; он поддерживает различные VPN-протоколы. Вы можете сами объединить несколько подключений в цепь с помощью поддерживаемых протоколов ниже.\n\nОдно подключение аналогично простой VPN-сети. Три подключения (для продвинутых пользователей) — классическая «луковая» маршрутизация. Если не используется ни одно подключение, то трафик не проходит по VPN-туннелю и открыт для просмотра.';

  @override
  String get deletingOpenVPNAndWireguardHopsWillLose =>
      'Удалив подключения OpenVPN и Wireguard, вы потеряете сопутствующие учетные данные и конфигурацию подключения. Не забудьте перед этим сохранить всю нужную информацию.';

  @override
  String get thisCannotBeUndoneToSaveThisIdentity =>
      'Это действие невозможно отменить. Чтобы сохранить идентификатор, выберите «Отмена» и воспользуйтесь функцией «Экспорт»';

  @override
  String get unlockTime => 'Срок раблокировки';

  @override
  String get chooseChain => 'Выберите цепь';

  @override
  String get unlocking => 'разблокировка';

  @override
  String get unlocked => 'Розблокированы';

  @override
  String get orchidTransaction => 'Транзакция Orchid';

  @override
  String get confirmations => 'Подтверждения';

  @override
  String get pending => 'Ожидание...';

  @override
  String get txHash => 'Хэш транз.:';

  @override
  String get allOfYourFundsAreAvailableForWithdrawal =>
      'Все ваши средства доступны для вывода.';

  @override
  String maxWithdrawOfYourTotalFundsCombinedFunds(
      String maxWithdraw, String totalFunds) {
    return 'В данный момент для вывода доступны $maxWithdraw (всего у вас $totalFunds).';
  }

  @override
  String get alsoUnlockRemainingDeposit =>
      'Также разблокировать оставшийся депозит';

  @override
  String get ifYouSpecifyLessThanTheFullAmountFundsWill =>
      'Если вы укажете не всю сумму, средства будут в первую очередь списываться с вашего баланса.';

  @override
  String get forAdditionalOptionsSeeTheAdvancedPanel =>
      'Другие варианты см. на вкладке ДОПОЛНИТЕЛЬНО.';

  @override
  String get ifYouSelectTheUnlockDepositOptionThisTransactionWill =>
      'Если вы выберете вариант разблокировки депозита, указанная сумма немедленно спишется с вашего баланса и запустится процесс разблокировки оставшегося депозита.';

  @override
  String get depositFundsAreAvailableForWithdrawal24HoursAfterUnlocking =>
      'Средства на депозите можно будет вывести через 24 часа после разблокировки.';

  @override
  String get withdrawFundsFromYourOrchidAccountToYourCurrentWallet =>
      'Вывод средств с вашего счета Orchid на текущий кошелек.';

  @override
  String get withdrawAndUnlockFunds => 'ВЫВОД И РАЗБЛОКИРОВКА СРЕДСТВ';

  @override
  String get withdrawFunds => 'ВЫВОД СРЕДСТВ';

  @override
  String get withdrawFunds2 => 'Снять Средства';

  @override
  String get withdraw => 'Вывести';

  @override
  String get submitTransaction => 'ПОДТВЕРДИТЬ ТРАНЗАКЦИЮ';

  @override
  String get move => 'Переместить';

  @override
  String get now => 'Сейчас';

  @override
  String get amount => 'Сумма';

  @override
  String get available => 'Доступно';

  @override
  String get select => 'Выбрать';

  @override
  String get add => 'ДОБАВИТЬ';

  @override
  String get balanceToDeposit => 'С БАЛАНСА НА ДЕПОЗИТ';

  @override
  String get depositToBalance => 'С ДЕПОЗИТА НА БАЛАНС';

  @override
  String get setWarnedAmount => 'Задать сумму предупреждения';

  @override
  String get addFundsToYourOrchidAccountBalanceAndorDeposit =>
      'Добавить средства на баланс и/или депозит счета Orchid.';

  @override
  String get forGuidanceOnSizingYourAccountSee =>
      'Рекомендации по размещению сумм на счету вы найдете на сайте <link>orchid.com</link>';

  @override
  String currentTokenPreauthorizationAmount(String tokenType, String amount) {
    return 'Текущая предавторизация ($tokenType): $amount';
  }

  @override
  String get noWallet => 'Кошелек не указан';

  @override
  String get noWalletOrBrowserNotSupported =>
      'Не указан кошелек или не поддерживается браузер.';

  @override
  String get error => 'Ошибка';

  @override
  String get failedToConnectToWalletconnect =>
      'Не удалось подключиться к WalletConnect.';

  @override
  String get unknownChain => 'Неизвестная цепь';

  @override
  String get theOrchidAccountManagerDoesntSupportThisChainYet =>
      'Менеджер аккаунтов Orchid пока не поддерживает эту цепь.';

  @override
  String get orchidIsntOnThisChain => 'Эта цепь недоступна в Orchid.';

  @override
  String get theOrchidContractHasntBeenDeployedOnThisChainYet =>
      'Контракт Orchid пока не размещен в этой цепи.';

  @override
  String get moveFunds => 'ПЕРЕМЕСТИТЬ СРЕДСТВА';

  @override
  String get moveFunds2 => 'Переместить средства';

  @override
  String get lockUnlock => 'БЛОКИРОВАТЬ / РАЗБЛОКИРОВАТЬ';

  @override
  String yourDepositOfAmountIsUnlocked(String amount) {
    return 'Ваш депозит ($amount) разблокирован.';
  }

  @override
  String get locked => 'заблокирован';

  @override
  String yourDepositOfAmountIsUnlockingOrUnlocked(
      String amount, String unlockingOrUnlocked) {
    return 'Ваш депозит ($amount) $unlockingOrUnlocked.';
  }

  @override
  String theFundsWillBeAvailableForWithdrawalInTime(String time) {
    return 'Средства можно будет вывести через \$$time.';
  }

  @override
  String get lockDeposit => 'БЛОКИРОВАТЬ ДЕПОЗИТ';

  @override
  String get unlockDeposit => 'РАЗБЛОКИРОВАТЬ ДЕПОЗИТ';

  @override
  String get advanced => 'ДОПОЛНИТЕЛЬНО';

  @override
  String get linklearnMoreAboutOrchidAccountslink =>
      '<link>Подробнее об учетных записях Orchid</link>.';

  @override
  String estimatedCostToCreateAnOrchidAccountWith(String efficiency, int num) {
    return 'Примерная стоимость создания учетной записи Orchid с эффективностью $efficiency и $num билетами.';
  }

  @override
  String get chain => 'Цепь';

  @override
  String get token => 'Токен';

  @override
  String get minDeposit => 'Мин. депозит';

  @override
  String get minBalance => 'Мин. баланс';

  @override
  String get fundFee => 'Комиссия за пополнение';

  @override
  String get withdrawFee => 'Комиссия за вывод';

  @override
  String get tokenValues => 'ЗНАЧЕНИЯ ТОКЕНОВ';

  @override
  String get usdPrices => 'ЦЕНЫ В ДОЛЛ. США';

  @override
  String get settingAWarnedDepositAmountBeginsThe24HourWaiting =>
      'Указав сумму предупреждения, вы не сможете вывести средства с депозита в течение 24 часов.';

  @override
  String get duringThisPeriodTheFundsAreNotAvailableAsA =>
      'В течение этого времени средства не будут доступны в качестве депозита в сети Orchid.';

  @override
  String get fundsMayBeRelockedAtAnyTimeByReducingThe =>
      'Чтобы повторно заблокировать средство, уменьшите сумму предупреждения в любое время.';

  @override
  String get warn => 'Предупреждение';

  @override
  String get totalWarnedAmount => 'Общая сумма предупреждения';

  @override
  String get newIdentity => 'Новый идентификатор';

  @override
  String get importIdentity => 'Импорт идентификатора';

  @override
  String get exportIdentity => 'Экспорт идентификатора';

  @override
  String get deleteIdentity => 'Удалить идентификатор';

  @override
  String get importOrchidIdentity => 'Импорт идентификатора Orchid';

  @override
  String get funderAddress => 'Адрес пополняющего';

  @override
  String get contract => 'Контракт';

  @override
  String get txFee => 'Комиссия за транзакцию';

  @override
  String get show => 'Показать';

  @override
  String get rpc => 'RPC';

  @override
  String get errors => 'Ошибки';

  @override
  String get lastHour => 'Последний час';

  @override
  String get chainSettings => 'Настройки цепочки';

  @override
  String get price => 'Цена';

  @override
  String get failed => 'Неудачно';

  @override
  String get fetchGasPrice => 'Загрузка цены на газ';

  @override
  String get fetchLotteryPot => 'Загрузка баланса';

  @override
  String get lines => 'строки';

  @override
  String get filtered => 'отфильтровано';

  @override
  String get backUpYourIdentity => 'Сделайте резервную копию своей личности';

  @override
  String get accountSetUp => 'Настройка учетной записи';

  @override
  String get setUpAccount => 'Настроить учетную запись';

  @override
  String get generateIdentity => 'СОЗДАТЬ ИДЕНТИЧНОСТЬ';

  @override
  String get enterAnExistingOrchidIdentity =>
      'Введите существующий идентификатор <account_link>Orchid</account_link>';

  @override
  String get pasteTheWeb3WalletAddress =>
      'Вставьте ниже адрес кошелька web3, который вы будете использовать для пополнения своего счета.';

  @override
  String get funderWalletAddress => 'Адрес кошелька спонсора';

  @override
  String get yourOrchidIdentityPublicAddress =>
      'Ваш публичный адрес Orchid Identity';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get yesIHaveSavedACopyOf =>
      'Да, я сохранил копию своего закрытого ключа в безопасном месте.';

  @override
  String get backUpYourOrchidIdentityPrivateKeyYouWill =>
      'Создайте резервную копию закрытого ключа Orchid Identity <bold></bold>. Этот ключ понадобится вам для совместного использования, импорта или восстановления этого удостоверения и всех связанных учетных записей.';

  @override
  String get locked1 => 'запертый';

  @override
  String get unlockDeposit1 => 'Разблокировать депозит';

  @override
  String get changeWarnedAmountTo => 'Изменить сумму предупреждения на';

  @override
  String get setWarnedAmountTo => 'Установить сумму предупреждения на';

  @override
  String get currentWarnedAmount => 'Текущая сумма предупреждения';

  @override
  String get allWarnedFundsWillBeLockedUntil =>
      'Все предупрежденные средства будут заблокированы до тех пор, пока';

  @override
  String get balanceToDeposit1 => 'Баланс для депозита';

  @override
  String get depositToBalance1 => 'Депозит на баланс';

  @override
  String get advanced1 => 'продвинутый';

  @override
  String get add1 => 'добавлять';

  @override
  String get lockUnlock1 => 'Блокировать/разблокировать';

  @override
  String get viewLogs => 'Просмотр журналов';

  @override
  String get language => 'язык';

  @override
  String get systemDefault => 'Системные установки по умолчанию';

  @override
  String get identiconStyle => 'Идентикон Стиль';

  @override
  String get blockies => 'блоки';

  @override
  String get jazzicon => 'джазикон';

  @override
  String get contractVersion => 'Контрактная версия';

  @override
  String get version0 => 'Версия 0';

  @override
  String get version1 => 'Версия 1';

  @override
  String get connectedWithMetamask => 'Связано с метамаской';

  @override
  String get blockExplorer => 'проводник блоков';

  @override
  String get tapToMinimize => 'Нажмите, чтобы свернуть';

  @override
  String get connectWallet => 'Подключить кошелек';

  @override
  String get checkWallet => 'Проверить кошелек';

  @override
  String get checkYourWalletAppOrExtensionFor =>
      'Проверьте приложение или расширение Wallet на наличие ожидающего запроса.';

  @override
  String get test => 'тестовое задание';

  @override
  String get chainName => 'Название цепи';

  @override
  String get rpcUrl => 'URL-адрес RPC';

  @override
  String get tokenPrice => 'Цена токена';

  @override
  String get tokenPriceUsd => 'Цена токена в долларах США';

  @override
  String get addChain => 'Добавить цепочку';

  @override
  String get deleteChainQuestion => 'Удалить цепочку?';

  @override
  String get deleteUserConfiguredChain =>
      'Удалить настроенную пользователем цепочку';

  @override
  String get fundContractDeployer => 'Развертывание контракта фонда';

  @override
  String get deploySingletonFactory => 'Развернуть фабрику синглтонов';

  @override
  String get deployContract => 'Развернуть контракт';

  @override
  String get about => 'Около';

  @override
  String get dappVersion => 'Децентрализованная версия';

  @override
  String get viewContractOnEtherscan => 'Посмотреть контракт на Etherscan';

  @override
  String get viewContractOnGithub => 'Посмотреть контракт на Github';

  @override
  String get accountChanges => 'Изменения учетной записи';

  @override
  String get name => 'название';

  @override
  String get step1 =>
      '<bold>Шаг 1.</bold> Подключите кошелек ERC-20 с <link>достаточным количеством токенов</link> в нем.';

  @override
  String get step2 =>
      '<bold>Шаг 2.</bold> Скопируйте идентификатор Orchid из приложения Orchid, перейдя в раздел «Управление учетными записями» и коснувшись адреса.';

  @override
  String get connectOrCreate => 'Подключить или создать учетную запись Orchid';

  @override
  String get lockDeposit2 => 'Заблокировать депозит';

  @override
  String get unlockDeposit2 => 'Разблокировать депозит';

  @override
  String get enterYourWeb3 => 'Введите адрес вашего кошелька web3.';

  @override
  String get purchaseComplete => 'Покупка завершена';

  @override
  String get generateNewIdentity => 'Создать новую личность';

  @override
  String get copyIdentity => 'Копировать личность';

  @override
  String get yourPurchaseIsComplete =>
      'Ваша покупка завершена и сейчас обрабатывается блокчейном xDai, что может занять несколько минут. С помощью этой учетной записи для вас была создана схема по умолчанию. Вы можете следить за доступным балансом на главном экране или в личном кабинете.';

  @override
  String get circuitGenerated => 'Цепь сгенерирована';

  @override
  String get usingYourOrchidAccount =>
      'С помощью вашей учетной записи Orchid была сгенерирована цепь с одним переходом. Вы можете управлять этим с экрана компоновщика цепей.';
}
