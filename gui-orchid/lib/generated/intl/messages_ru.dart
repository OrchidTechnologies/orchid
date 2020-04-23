// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ru';

  static m0(num) => "${Intl.plural(num, zero: 'Подключения не настроены', one: 'Одно подключение настроено', few: '${num} подключения настроены', many: '${num} подключений настроены', other: '${num} подключений настроены')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "addAccount" : MessageLookupByLibrary.simpleMessage("Добавить счет"),
    "addHop" : MessageLookupByLibrary.simpleMessage("Добавить подключение"),
    "addOrchidAccount" : MessageLookupByLibrary.simpleMessage("Добавьте счет Orchid"),
    "advanced" : MessageLookupByLibrary.simpleMessage("Дополнительные"),
    "allowNoHopVPN" : MessageLookupByLibrary.simpleMessage("Позволить VPN без соединения"),
    "amount" : MessageLookupByLibrary.simpleMessage("Сумма"),
    "approximately" : MessageLookupByLibrary.simpleMessage("примерно"),
    "bandwidthIsPurchasedInAVpnMarketplaceSoPriceWill" : MessageLookupByLibrary.simpleMessage("Пропускная способность покупается на рынке VPN, поэтому цена будет колебаться в зависимости от динамики рынка."),
    "bandwidthValueWillVary" : MessageLookupByLibrary.simpleMessage("Значение пропускной способности будет варьироваться"),
    "basedOnYourBandwidth" : MessageLookupByLibrary.simpleMessage("На основании вашего использования полосы пропускания"),
    "beta" : MessageLookupByLibrary.simpleMessage("бета-версия"),
    "budget" : MessageLookupByLibrary.simpleMessage("Бюджет"),
    "buyCredits" : MessageLookupByLibrary.simpleMessage("Купить кредиты"),
    "buyPrepaidCreditsToGetStartedTheresNoMonthlyFee" : MessageLookupByLibrary.simpleMessage("Купите предоплаченные кредиты, чтобы начать. Там нет ежемесячной платы, и вы платите только за то, что вы используете."),
    "buyVpnCredits" : MessageLookupByLibrary.simpleMessage("Купить VPN кредиты"),
    "cancelButtonTitle" : MessageLookupByLibrary.simpleMessage("ОТМЕНА"),
    "changesWillTakeEffectInstruction" : MessageLookupByLibrary.simpleMessage("Изменения вступят в силу после перезапуска VPN."),
    "chooseKey" : MessageLookupByLibrary.simpleMessage("Выбрать ключ"),
    "chooseYourAmount" : MessageLookupByLibrary.simpleMessage("Выберите сумму"),
    "chooseYourPurchase" : MessageLookupByLibrary.simpleMessage("Выберите вашу покупку"),
    "clear" : MessageLookupByLibrary.simpleMessage("Очистить"),
    "clearThisInProgressTransactionExplain" : MessageLookupByLibrary.simpleMessage("Очистите эту незавершенную транзакцию. Это не возместит вашу покупку в приложении. Вы должны связаться с Orchid, чтобы решить эту проблему."),
    "config" : MessageLookupByLibrary.simpleMessage("Конфигурация"),
    "configuration" : MessageLookupByLibrary.simpleMessage("Конфигурация"),
    "configurationFailedInstruction" : MessageLookupByLibrary.simpleMessage("Не удалось сохранить конфигурацию. Проверьте синтаксис и попробуйте еще раз."),
    "configurationSaved" : MessageLookupByLibrary.simpleMessage("Конфигурация сохранена"),
    "confirmThisAction" : MessageLookupByLibrary.simpleMessage("Подтвердите это действие"),
    "connecting" : MessageLookupByLibrary.simpleMessage("Подключение ..."),
    "connectionDetail" : MessageLookupByLibrary.simpleMessage("Сведения о подключении"),
    "contactOrchid" : MessageLookupByLibrary.simpleMessage("Связаться Орхидея"),
    "copy" : MessageLookupByLibrary.simpleMessage("Копировать"),
    "copyDebugInfo" : MessageLookupByLibrary.simpleMessage("Копировать отладочную информацию"),
    "createACustomAccount" : MessageLookupByLibrary.simpleMessage("Создать пользовательский аккаунт"),
    "createFirstHop" : MessageLookupByLibrary.simpleMessage("Создать свое первое подключение и будьте в безопасности онлайн."),
    "createInstruction1" : MessageLookupByLibrary.simpleMessage("Чтобы создать подключение Orchid, нужно иметь счет Orchid. Откройте"),
    "createInstructions2" : MessageLookupByLibrary.simpleMessage("в браузере Web3 и следуйте инструкциям. Вставьте свой адрес Ethereum ниже."),
    "createOrchidAccount" : MessageLookupByLibrary.simpleMessage("Создайте счет Orchid"),
    "credentials" : MessageLookupByLibrary.simpleMessage("Учетные данные"),
    "curation" : MessageLookupByLibrary.simpleMessage("Курирование"),
    "curator" : MessageLookupByLibrary.simpleMessage("Куратор"),
    "defaultCurator" : MessageLookupByLibrary.simpleMessage("Стандартный куратор"),
    "delete" : MessageLookupByLibrary.simpleMessage("Удалить"),
    "deleteAllData" : MessageLookupByLibrary.simpleMessage("Удалить все данные"),
    "deleteTransaction" : MessageLookupByLibrary.simpleMessage("Удалить транзакцию"),
    "deposit" : MessageLookupByLibrary.simpleMessage("Депозит"),
    "destination" : MessageLookupByLibrary.simpleMessage("Назначение"),
    "destinationPort" : MessageLookupByLibrary.simpleMessage("Порт назначения"),
    "disconnecting" : MessageLookupByLibrary.simpleMessage("Отсоединение ..."),
    "enterLoginInformationInstruction" : MessageLookupByLibrary.simpleMessage("Введите информацию для входа для свого VPN-провайдера выше. Затем вставьте содержимое файла конфигурации OpenVPN провайдера в соответствующее поле."),
    "enterOvpnCredentials" : MessageLookupByLibrary.simpleMessage("Введите учетные данные OVPN"),
    "enterOvpnProfile" : MessageLookupByLibrary.simpleMessage("Введите профиль OVPN"),
    "enterYourCredentials" : MessageLookupByLibrary.simpleMessage("Введите свои учетные данные"),
    "ethereumAddress" : MessageLookupByLibrary.simpleMessage("Адрес Ethereum"),
    "export" : MessageLookupByLibrary.simpleMessage("Экспорт"),
    "exportHopsConfiguration" : MessageLookupByLibrary.simpleMessage("Экспорт конфигурации подключения"),
    "fetchingPurchasedPAC" : MessageLookupByLibrary.simpleMessage("Извлечение купленного PAC"),
    "gb" : MessageLookupByLibrary.simpleMessage("гигабайт"),
    "generateNewKey" : MessageLookupByLibrary.simpleMessage("Сгенерировать новый ключ"),
    "getHelpResolvingIssue" : MessageLookupByLibrary.simpleMessage("Получить помощь в решении этой проблемы."),
    "haveAnOrchidAccountOrVpnSubscription" : MessageLookupByLibrary.simpleMessage("У вас есть аккаунт Orchid или VPN-подписка?"),
    "help" : MessageLookupByLibrary.simpleMessage("Справка"),
    "hops" : MessageLookupByLibrary.simpleMessage("Подключения"),
    "host" : MessageLookupByLibrary.simpleMessage("Хост"),
    "iHaveAQRCode" : MessageLookupByLibrary.simpleMessage("У меня есть QR-код"),
    "iHaveAVPNSubscription" : MessageLookupByLibrary.simpleMessage("У меня есть подписка на VPN"),
    "iHaveOrchidAccount" : MessageLookupByLibrary.simpleMessage("У меня есть аккаунт Orchid"),
    "iWantToTryOrchid" : MessageLookupByLibrary.simpleMessage("Я хочу попробовать Orchid"),
    "import" : MessageLookupByLibrary.simpleMessage("Импорт"),
    "importAnOrchidAccount" : MessageLookupByLibrary.simpleMessage("Импортировать учетную запись Orchid"),
    "importHopsConfiguration" : MessageLookupByLibrary.simpleMessage("Импорт конфигурации подключения"),
    "importKey" : MessageLookupByLibrary.simpleMessage("Импортировать ключ"),
    "inYourWalletBrowserInstruction" : MessageLookupByLibrary.simpleMessage("в браузере своего кошелька, чтобы начать."),
    "invalidCode" : MessageLookupByLibrary.simpleMessage("Неверный код"),
    "invalidQRCode" : MessageLookupByLibrary.simpleMessage("Неверный QR-код"),
    "learnMoreButtonTitle" : MessageLookupByLibrary.simpleMessage("ПОДРОБНЕЕ"),
    "linkAnOrchidAccount" : MessageLookupByLibrary.simpleMessage("Связать аккаунт Orchid"),
    "loadMsg" : MessageLookupByLibrary.simpleMessage("Откройте"),
    "log" : MessageLookupByLibrary.simpleMessage("Журнал"),
    "manageConfiguration" : MessageLookupByLibrary.simpleMessage("Управление конфигурацией"),
    "myOrchidAccount" : MessageLookupByLibrary.simpleMessage("Мой счет Orchid"),
    "needAnAccount" : MessageLookupByLibrary.simpleMessage("Нужна учетная запись?"),
    "needMoreHelp" : MessageLookupByLibrary.simpleMessage("Нужна помощь?"),
    "newContent" : MessageLookupByLibrary.simpleMessage("Новый контент"),
    "newHop" : MessageLookupByLibrary.simpleMessage("Новое подключение"),
    "noVersion" : MessageLookupByLibrary.simpleMessage("Нет версии"),
    "nothingToDisplayYet" : MessageLookupByLibrary.simpleMessage("Пока нет данных. Трафик появится здесь, когда будет что показать."),
    "numHopsConfigured" : m0,
    "ofTraffic" : MessageLookupByLibrary.simpleMessage("Трафика"),
    "ok" : MessageLookupByLibrary.simpleMessage("ОК"),
    "okButtonTitle" : MessageLookupByLibrary.simpleMessage("ОК"),
    "onlyForTheOrchidApp" : MessageLookupByLibrary.simpleMessage("Только для приложения Орхидея"),
    "openSourceLicenses" : MessageLookupByLibrary.simpleMessage("Лицензии с открытым исходным кодом"),
    "openVPN" : MessageLookupByLibrary.simpleMessage("OpenVPN"),
    "openVPNHop" : MessageLookupByLibrary.simpleMessage("Подключение OpenVPN"),
    "orchid" : MessageLookupByLibrary.simpleMessage("Orchid"),
    "orchidConnecting" : MessageLookupByLibrary.simpleMessage("Orchid подключается"),
    "orchidDisabled" : MessageLookupByLibrary.simpleMessage("Служба Orchid отключена"),
    "orchidDisconnecting" : MessageLookupByLibrary.simpleMessage("Orchid отключается"),
    "orchidHop" : MessageLookupByLibrary.simpleMessage("Подключение Orchid"),
    "orchidIsRunning" : MessageLookupByLibrary.simpleMessage("Орхидея бежит!"),
    "orchidIsUniqueAsItSupportsMultipleVPN" : MessageLookupByLibrary.simpleMessage("Orchid уникален тем, что поддерживает несколько VPN-подключений одновременно. Каждое VPN-соединение является «прыжком».\n\nКаждый прыжок нуждается в активном аккаунте, выберите опцию ниже."),
    "orchidOverview" : MessageLookupByLibrary.simpleMessage("Обзор Orchid"),
    "orchidRequiresAccountInstruction" : MessageLookupByLibrary.simpleMessage("Для использования Orchid нужно иметь счет Orchid. Отсканируйте или добавьте свой существующий счет ниже, чтобы начать работу."),
    "orchidRequiresOXT" : MessageLookupByLibrary.simpleMessage("Orchid требует OXT"),
    "orchidTokensInTheFormOfAccessCreditsAreUnable" : MessageLookupByLibrary.simpleMessage("Жетоны орхидей в форме кредитов доступа не могут быть использованы или перенесены за пределы приложения Orchid."),
    "oxt" : MessageLookupByLibrary.simpleMessage("OXT"),
    "pacPurchaseWaiting" : MessageLookupByLibrary.simpleMessage("PAC Покупка Ожидание"),
    "password" : MessageLookupByLibrary.simpleMessage("Пароль"),
    "paste" : MessageLookupByLibrary.simpleMessage("Вставить"),
    "pasteYourOVPN" : MessageLookupByLibrary.simpleMessage("Вставьте свой файл конфигурации OVPN здесь"),
    "payOnlyForWhatYouUseWithVpnCreditsOnly" : MessageLookupByLibrary.simpleMessage("Платите только за то, что вы используете с кредитами VPN, только потраченные, когда VPN активен. Нет срока действия, ежемесячные платежи или сборы."),
    "preparingPurchase" : MessageLookupByLibrary.simpleMessage("Подготовка покупки"),
    "privacyPolicy" : MessageLookupByLibrary.simpleMessage("Политика конфиденциальности"),
    "purchase" : MessageLookupByLibrary.simpleMessage("покупка"),
    "purchaseError" : MessageLookupByLibrary.simpleMessage("Ошибка покупки"),
    "purchasePAC" : MessageLookupByLibrary.simpleMessage("Купить аккаунт (PAC)"),
    "pushToConnect" : MessageLookupByLibrary.simpleMessage("Нажмите, чтобы подключиться."),
    "queryBalances" : MessageLookupByLibrary.simpleMessage("Баланс запросов"),
    "rateLimit" : MessageLookupByLibrary.simpleMessage("Ограничение ставки"),
    "readTheGuide" : MessageLookupByLibrary.simpleMessage("Просмотрите руководство"),
    "remove" : MessageLookupByLibrary.simpleMessage("Удалить"),
    "reset" : MessageLookupByLibrary.simpleMessage("Сбросить"),
    "retry" : MessageLookupByLibrary.simpleMessage("Retry"),
    "retryPurchasedPAC" : MessageLookupByLibrary.simpleMessage("Повторите попытку покупки PAC"),
    "retryingPurchasedPAC" : MessageLookupByLibrary.simpleMessage("Повторная попытка покупки PAC"),
    "save" : MessageLookupByLibrary.simpleMessage("Сохранить"),
    "saveButtonTitle" : MessageLookupByLibrary.simpleMessage("СОХРАНИТЬ"),
    "saved" : MessageLookupByLibrary.simpleMessage("Сохранено"),
    "scan" : MessageLookupByLibrary.simpleMessage("Сканировать"),
    "scanOrPasteAccount" : MessageLookupByLibrary.simpleMessage("Сканирование или вставка аккаунта"),
    "scanOrPasteYourExistingAccountBelowToAddIt" : MessageLookupByLibrary.simpleMessage("Сканируйте или вставьте существующую учетную запись ниже, чтобы добавить ее в качестве прыжка"),
    "scanYourExistingAccountCreateACustomAccountOrEnter" : MessageLookupByLibrary.simpleMessage("Сканируйте существующую учетную запись, создайте пользовательскую учетную запись или введите учетные данные OVPN."),
    "search" : MessageLookupByLibrary.simpleMessage("Поиск"),
    "seeTheOptions" : MessageLookupByLibrary.simpleMessage("Смотрите варианты"),
    "selectYourHop" : MessageLookupByLibrary.simpleMessage("Выберите подключение"),
    "setUpAccount" : MessageLookupByLibrary.simpleMessage("Настроить учетную запись"),
    "settings" : MessageLookupByLibrary.simpleMessage("Настройки"),
    "settingsButtonTitle" : MessageLookupByLibrary.simpleMessage("НАСТРОЙКИ"),
    "setup" : MessageLookupByLibrary.simpleMessage("Установка"),
    "shareOrchidAccount" : MessageLookupByLibrary.simpleMessage("Поделиться счетом Orchid"),
    "showInstructions" : MessageLookupByLibrary.simpleMessage("Показать инструкции"),
    "showStatusPage" : MessageLookupByLibrary.simpleMessage("Показывать страницу статуса"),
    "signerKey" : MessageLookupByLibrary.simpleMessage("Ключ подписанта"),
    "sourcePort" : MessageLookupByLibrary.simpleMessage("Порт источника"),
    "status" : MessageLookupByLibrary.simpleMessage("Статус"),
    "theCodeYouPastedDoesNot" : MessageLookupByLibrary.simpleMessage("Вставленный код не содержит допустимой конфигурации счета."),
    "theQRCodeYouScannedDoesNot" : MessageLookupByLibrary.simpleMessage("Отсканированный код не содержит допустимой конфигурации счета."),
    "thereWasAnErrorInPurchasingContact" : MessageLookupByLibrary.simpleMessage("Произошла ошибка при покупке. Пожалуйста, свяжитесь со службой поддержки Orchid."),
    "thisReleaseVPNInstruction" : MessageLookupByLibrary.simpleMessage("Это передовой VPN-клиент Orchid, поддерживающий мульти-подключения и анализ локального трафика."),
    "thisWillDeleteRecorded" : MessageLookupByLibrary.simpleMessage("Это действие удалит все записанные данные о трафике в приложении."),
    "time" : MessageLookupByLibrary.simpleMessage("Время"),
    "toGetStartedInstruction" : MessageLookupByLibrary.simpleMessage("Для начала включите VPN."),
    "traffic" : MessageLookupByLibrary.simpleMessage("Трафик"),
    "trafficListView" : MessageLookupByLibrary.simpleMessage("просмотреть список трафика"),
    "trafficMonitoringOnly" : MessageLookupByLibrary.simpleMessage("Только мониторинг трафика"),
    "turnOnToActivate" : MessageLookupByLibrary.simpleMessage("Включите Orchid, чтобы активировать подключения и защитить свой трафик"),
    "username" : MessageLookupByLibrary.simpleMessage("Имя пользователя"),
    "version" : MessageLookupByLibrary.simpleMessage("Версия"),
    "viewOrModifyRateLimit" : MessageLookupByLibrary.simpleMessage("Просмотр или изменение ограничения ставки."),
    "warningExportedConfiguration" : MessageLookupByLibrary.simpleMessage("Предупреждение: экспортированная конфигурация включает подпись секретного закрытого ключа для экспортируемого подключения. Раскрывая закрытие ключи, вы можете потерять все средства в соответствующих счетах Orchid."),
    "warningImportedConfiguration" : MessageLookupByLibrary.simpleMessage("Предупреждение: импортированная конфигурация заменит любые существующие подключения, созданные в приложении. Ключи подписанта, ранее сгенерированные или импортированные на этом устройстве, сохраняются и остаются доступными для создания новых подключений, однако все остальные настройки, включая настройки подключения OpenVPN, будут потеряны."),
    "warningThesefeature" : MessageLookupByLibrary.simpleMessage("Предупреждение: эти функции предназначены только для опытных пользователей. Пожалуйста, прочитайте все инструкции."),
    "welcomeToOrchid" : MessageLookupByLibrary.simpleMessage("Добро пожаловать в Orchid"),
    "whoops" : MessageLookupByLibrary.simpleMessage("Ошибочка"),
    "youNeedEthereumWallet" : MessageLookupByLibrary.simpleMessage("Чтобы создать счет Orchid, вам понадобится кошелек Ethereum.")
  };
}
